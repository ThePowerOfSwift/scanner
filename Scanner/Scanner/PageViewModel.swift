//
//  PageViewModel.swift
//  Scanner
//
//  Created by Tamás Zahola on 12/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class PageViewModel {
    
    private let documentStore:DocumentStore
    private let workflow:Workflow
    
    private(set) var image:UIImage?
    
    init(documentStore:DocumentStore, workflow:Workflow) {
        self.documentStore = documentStore
        self.workflow = workflow
        
        self.image = self.workflow.selectedPage!.loadImage()
    }
}