//
//  DocumentManager.swift
//  Scanner
//
//  Created by Tamás Zahola on 15/07/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation
import UIKit

class Page : Equatable {
    private let imageName:String
    
    init(_ imageName:String) {
        self.imageName = imageName
    }
}

func ==(a:Page, b:Page) -> Bool {
    return a === b
}

class Document : Equatable {
    let store:DocumentStore
    
    var title:String?
    private(set) var pages:[Page] = []
    
    private init(_ store:DocumentStore) {
        self.store = store
    }
    
    func createPage(image:UIImage) -> Page? {
        let imageName = NSUUID.new().UUIDString
        if let imageData = UIImageJPEGRepresentation(image, 0.9) {
            if self.store.storeDataWithName(imageData, name: imageName) {
                let page = Page(imageName)
                self.pages.append(page)
                
                return page
            }
        }
        return nil
    }
}

func ==(a:Document, b:Document) -> Bool {
    return a === b
}

class DocumentStore {
    private let fileManager:NSFileManager
    
    let path:String
    private(set) var documents:[Document]
    
    init?(_ fileManager:NSFileManager, _ path:String) {
        self.fileManager = fileManager
        self.path = path
        self.documents = []
        
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
                            
                            if imageName != nil {
                                let page = Page(imageName!)
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
    
    private func pathForName(name:String) -> String {
        return self.path.stringByAppendingPathComponent(name)
    }
    
    private func storeDataWithName(data:NSData, name:String) -> Bool {
        let path = self.pathForName(name)
        return self.fileManager.createFileAtPath(path, contents: data, attributes: nil)
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
                    "imageName" : page.imageName
                ]
            }
            
            if let title = document.title {
                archivedDocument["title"] = title
            }
            return archivedDocument
        }
        
        let documentsData = NSKeyedArchiver.archivedDataWithRootObject(archivedRepresentation)
        return self.storeDataWithName(documentsData, name: "info")
    }
    
}
