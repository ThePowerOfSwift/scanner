//
//  DocumentsViewModel.swift
//  Scanner
//
//  Created by Tamás Zahola on 04/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import Foundation

class DocumentListItem {

    let title:String?
    
    init(_ title:String?) {
        self.title = title
    }
    
}

class DocumentListViewModel : ViewModel {
    
    private let documentStore:DocumentStore
    
    private(set) var documents:[DocumentListItem]? {
        didSet {
            self.notifyObservers()
        }
    }
    
    init(_ documentStore:DocumentStore) {
        self.documentStore = documentStore
        
        super.init()
        
        self.refresh()
    }
    
    func createDocumentWithName(name:String) -> Void {
        let document = documentStore.createDocument()
        document.title = name
        documentStore.save()
        refresh()
    }
    
    private func refresh() -> Void {
        self.documents = documentStore.documents.map {
            (let document) -> DocumentListItem in
            return DocumentListItem(document.title)
        }
    }
    
}
