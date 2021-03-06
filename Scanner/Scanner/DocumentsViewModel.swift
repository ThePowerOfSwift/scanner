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

class DocumentListViewModel {
    static let ViewModelChangedNotification = "DocumentListViewModelChangedNotification"
    
    private let documentStore:DocumentStore
    private let workflow:Workflow
    private var observerToken:NSObjectProtocol!
    
    private(set) var documents:[DocumentListItem]?
    
    init(documentStore:DocumentStore, workflow:Workflow) {
        self.documentStore = documentStore
        self.workflow = workflow
        
        self.observerToken = NSNotificationCenter.defaultCenter().addObserverForName(DocumentStore.StoreSavedNotification, object: self.documentStore, queue: nil) {
            [unowned self] (notification) -> Void in
            self.refresh()
        }
        
        self.refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self.observerToken)
    }
    
    func createDocumentWithName(name:String) {
        let document = documentStore.createDocument()
        document.title = name
        documentStore.save()
    }
    
    func deleteDocumentAtIndex(index:Int) {
        self.documentStore.deleteDocument(self.documentStore.documents[index])
        documentStore.save()
    }
    
    func renameDocumentAtIndex(index:Int, newTitle:String) {
        self.documentStore.documents[index].title = newTitle
        self.documentStore.save()
    }
    
    func selectDocumentAtIndex(index:Int) {
        self.workflow.selectDocument(self.documentStore.documents[index])
    }
    
    private func refresh() {
        self.documents = documentStore.documents.map {
            (let document) -> DocumentListItem in
            return DocumentListItem(document.title)
        }
        NSNotificationCenter.defaultCenter().postNotificationName(DocumentListViewModel.ViewModelChangedNotification, object: self, userInfo: nil)
    }
}
