//
//  DocumentManager.swift
//  Scanner
//
//  Created by Tamás Zahola on 15/07/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation

class Page {

}

class Document {
    private(set) var pages:[Page]?
}

class DocumentStore {
    
    private let fileManager:NSFileManager
    
    init?(_ fileManager:NSFileManager) {
        self.fileManager = fileManager
    }
    
}