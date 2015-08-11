//
//  Workflow.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation

class Workflow {
    
    private(set) var selectedDocument:Document?
    private(set) var selectedPage:Page?
    
    func selectDocument(document:Document) {
        self.selectedDocument = document
    }
    
    func selectPage(page:Page) {
        self.selectedPage = page
    }
    
}
