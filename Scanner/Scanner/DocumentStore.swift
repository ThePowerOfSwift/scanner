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

class Page : Equatable, Hashable {
    var hashValue: Int { get { return ObjectIdentifier(self).hashValue } }
    
    unowned private let document:Document
    
    private let imageName:String
    var cropRect:CGRect {
        didSet {
            if find(self.document.updatedPages, self) == nil {
                self.document.updatedPages.insert(self)
                self.document.store.updatedDocuments.insert(self.document)
            }
        }
    }
    
    private init(document:Document, imageName:String, cropRect:CGRect) {
        self.document = document
        self.imageName = imageName
        self.cropRect = cropRect
    }
    
    func loadRawImage() -> UIImage? {
        return imageAtPath(self.document.store.pathForName(self.imageName))
    }
    
    func loadImage() -> UIImage? {
        return imageAtPath(self.document.store.pathForName(self.imageName), self.cropRect)
    }
    
    func loadThumbnail() -> UIImage? {
        return thumbnailFromImage(self.document.store.pathForName(self.imageName), self.cropRect)
    }
}

func ==(a:Page, b:Page) -> Bool {
    return a === b
}

class Document : Equatable, Hashable {
    var hashValue: Int { get { return ObjectIdentifier(self).hashValue } }
    
    unowned private let store:DocumentStore
    
    var title:String? {
        didSet {
            if find(self.store.updatedDocuments, self) == nil {
                self.store.updatedDocuments.insert(self)
            }
        }
    }
    private(set) var pages:[Page] = []
    
    private var addedPages:Set<Page> = []
    private var updatedPages:Set<Page> = []
    private var deletedPages:Set<Page> = []
    
    private init(_ store:DocumentStore) {
        self.store = store
    }
    
    func createPage(image:UIImage) -> Page? {
        let imageName = NSUUID.new().UUIDString
        if let imageData = UIImageJPEGRepresentation(image, 0.9) {
            if self.store.storeDataWithName(imageData, name: imageName) {
                let page = Page(document: self, imageName: imageName, cropRect: CGRect(origin: CGPointZero, size: image.size))
                self.pages.append(page)
                self.addedPages.insert(page)
                self.store.updatedDocuments.insert(self)
                
                return page
            }
        }
        return nil
    }
    
    func deletePage(page:Page) {
        self.pages.removeAtIndex(find(self.pages, page)!)
        self.store.itemsToBeDeleted.append(page.imageName)
        self.deletedPages.insert(page)
        self.store.updatedDocuments.insert(self)
    }
}

func ==(a:Document, b:Document) -> Bool {
    return a === b
}

class DocumentStore {
    static let StoreSavedNotification = "StoreSavedNotification"
    
    static let StoreSavedNotificationAddedDocuments = "StoreSavedNotificationAddedDocuments"
    static let StoreSavedNotificationUpdatedDocuments = "StoreSavedNotificationUpdatedDocuments"
    static let StoreSavedNotificationDeletedDocuments = "StoreSavedNotificationDeletedDocuments"
    
    static let StoreSavedNotificationAddedPages = "StoreSavedNotificationAddedPages"
    static let StoreSavedNotificationUpdatedPages = "StoreSavedNotificationUpdatedPages"
    static let StoreSavedNotificationDeletedPages = "StoreSavedNotificationDeletedPages"
    
    typealias StoreSavedNotificationAddedPagesType = Set<Page>
    typealias StoreSavedNotificationUpdatedPagesType = Set<Page>
    typealias StoreSavedNotificationDeletedPagesType = Set<Page>
    typealias StoreSavedNotificationAddedDocumentsType = Set<Document>
    typealias StoreSavedNotificationUpdatedDocumentsType = [Document:[String:Set<Page>]]
    typealias StoreSavedNotificationDeletedDocumentsType = Set<Document>
    
    private let fileManager:NSFileManager
    
    let path:String
    private(set) var documents:[Document] = []
    
    private var itemsToBeDeleted:[String] = []
    
    // tracking added/updated/deleted documents for notifications
    private var addedDocuments:Set<Document> = []
    private var updatedDocuments:Set<Document> = []
    private var deletedDocuments:Set<Document> = []
    
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
                                let page = Page(document: document, imageName: imageName!, cropRect: cropRect!)
                                document.pages.append(page)
                            }
                        }
                        
                        if let title = archivedDocument["title"] as? String {
                            document.title = title
                        }
                        
                        document.addedPages = []
                        document.updatedPages = []
                        document.deletedPages = []
                        
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
            
            var updatedDocumentsInfo = DocumentStore.StoreSavedNotificationUpdatedDocumentsType()
            for updatedDocument in self.updatedDocuments {
                updatedDocumentsInfo[updatedDocument] = [
                    DocumentStore.StoreSavedNotificationAddedPages : updatedDocument.addedPages,
                    DocumentStore.StoreSavedNotificationUpdatedPages : updatedDocument.updatedPages,
                    DocumentStore.StoreSavedNotificationDeletedPages : updatedDocument.deletedPages
                ]
                updatedDocument.addedPages = []
                updatedDocument.updatedPages = []
                updatedDocument.deletedPages = []
            }
            
            var userInfo = [NSObject:AnyObject]()
            userInfo[DocumentStore.StoreSavedNotificationAddedDocuments] = self.addedDocuments
            userInfo[DocumentStore.StoreSavedNotificationUpdatedDocuments] = updatedDocumentsInfo
            userInfo[DocumentStore.StoreSavedNotificationDeletedDocuments] = self.deletedDocuments
            
            self.addedDocuments = []
            self.updatedDocuments = []
            self.deletedDocuments = []
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                DocumentStore.StoreSavedNotification,
                object: self,
                userInfo: userInfo)
        }
        
        return didStore
    }
}
