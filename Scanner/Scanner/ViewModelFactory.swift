//
//  ViewModelRegistry.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation

class ViewModelFactory {
    static let sharedInstance = ViewModelFactory()
    
    var documentStore:DocumentStore!
    var workflow:Workflow!
    
    func documentListViewModel() -> DocumentListViewModel {
        return DocumentListViewModel(documentStore: self.documentStore, workflow: self.workflow)
    }
    
    func pagesViewModel() -> PagesViewModel {
        return PagesViewModel(documentStore: self.documentStore, workflow: self.workflow)
    }
    
    func pageViewModel() -> PageViewModel {
        return PageViewModel(documentStore: self.documentStore, workflow: self.workflow)
    }
}
