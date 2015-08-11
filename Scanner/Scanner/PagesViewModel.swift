//
//  PagesViewModel.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit
import ImageIO

class PageItemViewModel {
    let thumbnail:UIImage
    
    init(_ thumbnail:UIImage) {
        self.thumbnail = thumbnail
    }
}

class PagesViewModel {
    static let ViewModelChangedNotification = "PagesViewModelChangedNotification"
    
    private let documentStore:DocumentStore
    private let workflow:Workflow
    private var observerToken:NSObjectProtocol!
    
    private let document:Document
    
    var documentTitle:String? {
        get {
            return self.document.title
        }
    }
    
    private(set) var pages:[PageItemViewModel] = []
    
    init(documentStore:DocumentStore, workflow:Workflow) {
        self.documentStore = documentStore
        self.workflow = workflow
        self.document = self.workflow.selectedDocument!
        
        self.observerToken = NSNotificationCenter.defaultCenter().addObserverForName(DocumentStore.StoreSavedNotification, object: self.documentStore, queue: nil) {
            [unowned self] (notification) -> Void in
            self.refresh()
        }
        
        self.refresh()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self.observerToken)
    }
    
    func createPageFromImage(image:UIImage) {
        self.document.createPage(image)
        self.documentStore.save()
    }
    
    func selectPageAtIndex(index:Int) {
        self.workflow.selectPage(self.document.pages[index])
    }
    
    func refresh() {
        self.pages = self.document.pages.map {
            (let page) -> PageItemViewModel in
            let image = page.loadThumbnail()!
            return PageItemViewModel(image) // TODO: error handling
        }
        NSNotificationCenter.defaultCenter().postNotificationName(PagesViewModel.ViewModelChangedNotification, object: self)
    }
}
