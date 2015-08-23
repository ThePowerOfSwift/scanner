//
//  DocumentManager.swift
//  Scanner
//
//  Created by Tamás Zahola on 15/07/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

class Page : Equatable {
    unowned private let store:DocumentStore
    
    private let imageName:String
    var cropRect:CGRect
    
    private init(store:DocumentStore, imageName:String, cropRect:CGRect) {
        self.store = store
        self.imageName = imageName
        self.cropRect = cropRect
    }
    
    func loadRawImage() -> UIImage? {
        return imageAtPath(self.store.pathForName(self.imageName))
    }
    
    func loadImage() -> UIImage? {
        return imageAtPath(self.store.pathForName(self.imageName), self.cropRect)
    }
    
    func loadThumbnail() -> UIImage? {
        return thumbnailFromImage(self.store.pathForName(self.imageName), self.cropRect)
    }
}

func ==(a:Page, b:Page) -> Bool {
    return a === b
}

class Document : Equatable {
    unowned private let store:DocumentStore
    
    var title:String?
    private(set) var pages:[Page] = []
    
    private init(_ store:DocumentStore) {
        self.store = store
    }
    
    func createPage(image:UIImage) -> Page? {
        let imageName = NSUUID.new().UUIDString
        if let imageData = UIImageJPEGRepresentation(image, 0.9) {
            if self.store.storeDataWithName(imageData, name: imageName) {
                let page = Page(store: self.store, imageName: imageName, cropRect: CGRect(origin: CGPointZero, size: image.size))
                self.pages.append(page)
                
                return page
            }
        }
        return nil
    }
    
    func deletePage(page:Page) {
        self.pages.removeAtIndex(find(self.pages, page)!)
        self.store.itemsToBeDeleted.append(page.imageName)
    }
}

func ==(a:Document, b:Document) -> Bool {
    return a === b
}

class DocumentStore {
    // TODO: keep track of documents added/updated/deleted since last save and include them in the notification
    static let StoreSavedNotification = "StoreSavedNotification"
    
    private let fileManager:NSFileManager
    
    let path:String
    private(set) var documents:[Document] = []
    
    private var itemsToBeDeleted:[String] = []
    
    init?(fileManager:NSFileManager, path:String) {
        self.fileManager = fileManager
        self.path = path
        
        if !self.fileManager.fileExistsAtPath(path) {
            var error:NSErrorPointer = nil
            let didCreate = self.fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: error)
            
            if !didCreate {
                return nil
            }
        }
        
        if let data = self.loadDataWithName("info") {
            if let archivedDocuments = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [[String:AnyObject]] {
                for archivedDocument in archivedDocuments {
                    if let archivedPages = archivedDocument["pages"] as? [[String:AnyObject]] {
                        let document = Document(self)
                        
                        for archivedPage in archivedPages {
                            let imageName = archivedPage["imageName"] as? String
                            let cropRectString = archivedPage["cropRect"] as? String
                            let cropRect:CGRect? = cropRectString != nil ? CGRectFromString(cropRectString) : nil
                            
                            if imageName != nil && cropRect != nil {
                                let page = Page(store: self, imageName: imageName!, cropRect: cropRect!)
                                document.pages.append(page)
                            }
                        }
                        
                        if let title = archivedDocument["title"] as? String {
                            document.title = title
                        }
                        
                        self.documents.append(document)
                    }
                }
            }
        }
    }
    
    func createDocument() -> Document {
        let document = Document(self)
        self.documents.append(document)
        return document
    }
    
    func deleteDocument(document:Document) {
        let document = self.documents.removeAtIndex(find(self.documents, document)!)
        for page in document.pages {
            self.itemsToBeDeleted.append(page.imageName)
        }
    }
    
    private func pathForName(name:String) -> String {
        return self.path.stringByAppendingPathComponent(name)
    }
    
    private func storeDataWithName(data:NSData, name:String) -> Bool {
        let path = self.pathForName(name)
        return self.fileManager.createFileAtPath(path, contents: data, attributes: nil)
    }
    
    private func deleteDataWithName(name:String) -> Bool {
        let path = self.pathForName(name)
        return self.fileManager.removeItemAtPath(path, error: nil)
    }
    
    private func loadDataWithName(name:String) -> NSData? {
        let path = self.pathForName(name)
        return self.fileManager.contentsAtPath(path)
    }
    
    func save() -> Bool {
        let archivedRepresentation = self.documents.map {
            (let document) -> [String:AnyObject] in
            
            var archivedDocument = [String:AnyObject]()
            
            archivedDocument["pages"] = document.pages.map {
                (let page) -> [String:AnyObject] in
                return [
                    "imageName" : page.imageName,
                    "cropRect" : NSStringFromCGRect(page.cropRect) as String
                ]
            }
            
            if let title = document.title {
                archivedDocument["title"] = title
            }
            return archivedDocument
        }
        
        let documentsData = NSKeyedArchiver.archivedDataWithRootObject(archivedRepresentation)
        let didStore = self.storeDataWithName(documentsData, name: "info")
        
        if didStore {
            for itemName in self.itemsToBeDeleted {
                self.deleteDataWithName(itemName) // TODO: error handling
            }
            self.itemsToBeDeleted = []
            
            NSNotificationCenter.defaultCenter().postNotificationName(DocumentStore.StoreSavedNotification, object: self, userInfo: nil)
        }
        
        return didStore
    }
}
