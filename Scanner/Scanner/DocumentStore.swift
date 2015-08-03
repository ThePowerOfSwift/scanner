//
//  DocumentManager.swift
//  Scanner
//
//  Created by Tamás Zahola on 15/07/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation

class Page : Equatable {
}

func ==(a:Page, b:Page) -> Bool {
    return a === b
}

class Document : Equatable {
    let store:DocumentStore
    
    private(set) var pages:[Page] = []
    
    private init(_ store:DocumentStore) {
        self.store = store
    }
    
    func createPage() -> Page {
        let page = Page()
        self.pages.append(page)
        return page
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
    }
    
    func save() -> Void {
        let infoFilePath = self.path.stringByAppendingPathComponent("info")
        let documentsData = NSKeyedArchiver.archivedDataWithRootObject(documents)
        self.fileManager.createFileAtPath(infoFilePath, contents: documentsData, attributes: nil)
    }
    
}
