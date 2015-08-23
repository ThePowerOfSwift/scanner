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
    private(set) var cropRect:CGRect?
    
    init(documentStore:DocumentStore, workflow:Workflow) {
        self.documentStore = documentStore
        self.workflow = workflow
        
        self.image = self.workflow.selectedPage!.loadRawImage()
        self.cropRect = self.workflow.selectedPage!.cropRect
    }
    
    func cancel() {
        self.workflow.deselectedPage()
    }
    
    func saveCropRect(cropRect:CGRect) {
        let x = max(0, round(cropRect.origin.x))
        let y = max(0, round(cropRect.origin.y))
        let width = min(image!.size.width, round(cropRect.width))
        let height = min(image!.size.height, round(cropRect.height))
        let newCropRect = CGRect(x: x, y: y, width: width, height: height)
        
        self.workflow.selectedPage!.cropRect = newCropRect
        self.documentStore.save()
        self.workflow.deselectedPage()
    }
}
