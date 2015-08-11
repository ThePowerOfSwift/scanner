//
//  PageViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 07/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class PageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    private(set) var viewModel:PageViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = ViewModelFactory.sharedInstance.pageViewModel()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("tappedView")))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.imageView.image = self.viewModel.image
    }
    
    func tappedView() {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}