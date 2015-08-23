//
//  MainNavigationController.swift
//  Scanner
//
//  Created by Tamás Zahola on 21/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class MainNavigationController : UINavigationController, UIGestureRecognizerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.interactivePopGestureRecognizer.delegate = self
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == self.interactivePopGestureRecognizer {
            return !(self.topViewController is PagesViewController)
        } else {
            return true
        }
    }
}