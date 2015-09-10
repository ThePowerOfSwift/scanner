//
//  PageViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 07/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

enum CropPanMode {
    case TopLeft
    case Left
    case BottomLeft
    case Bottom
    case BottomRight
    case Right
    case TopRight
    case Top
}

class ExtendedScrollView : UIScrollView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return true
    }
}

class CropRectView : UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let expandedBounds = CGRectInset(self.bounds, -20, -20)
        let contractedBounds = CGRectInset(self.bounds, 20, 20)
        return CGRectContainsPoint(expandedBounds, point) && !CGRectContainsPoint(contractedBounds, point)
    }
}

class PageViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var cropRectView: CropRectView!
    private var cropRectOriginalFrame:CGRect!
    private var cropPanMode:CropPanMode!
    
    private(set) var viewModel:PageViewModel!
    
    private var maskLayer:CAShapeLayer!
    
    private var cropViewMaxWidth:CGFloat {
        get {
            return UIScreen.mainScreen().bounds.width - 120
        }
    }
    
    private var cropViewMaxHeight:CGFloat {
        get {
            return UIScreen.mainScreen().bounds.height - 120
        }
    }
    
    private func setScrollViewConstraintsForCropRect(cropRect:CGRect) {
        let cropRectAspectRatio = cropRect.width / cropRect.height
        if self.cropViewMaxWidth / cropRect.width < self.cropViewMaxHeight / cropRect.height {
            self.scrollViewWidth.constant = self.cropViewMaxWidth
            self.scrollViewHeight.constant = self.scrollViewWidth.constant / cropRectAspectRatio
        } else {
            self.scrollViewHeight.constant = self.cropViewMaxHeight
            self.scrollViewWidth.constant = self.scrollViewHeight.constant * cropRectAspectRatio
        }
    }
    
    deinit {
        self.maskLayer.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.maskLayer = CAShapeLayer()
        self.maskLayer.fillColor = self.view.backgroundColor!.CGColor
        self.maskLayer.fillRule = kCAFillRuleEvenOdd
        self.maskLayer.delegate = self
        self.view.layer.insertSublayer(self.maskLayer, below: self.cropRectView.layer)
        
        self.viewModel = ViewModelFactory.sharedInstance.pageViewModel()
        
        self.cropRectView.layer.borderWidth = 1 / self.cropRectView.layer.contentsScale
        self.cropRectView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.cropRectView.alpha = 0
        
        self.toolbar.alpha = 0
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("pannedCropRectView:"))
        self.cropRectView.addGestureRecognizer(panGestureRecognizer)
        
        self.setScrollViewConstraintsForCropRect(self.viewModel.cropRect!)
        
        self.imageViewWidth.constant = self.viewModel.image!.size.width
        self.imageViewHeight.constant = self.viewModel.image!.size.height
        
        self.scrollView.maximumZoomScale = 1
        
        self.scrollView.minimumZoomScale = max(
            self.scrollViewWidth.constant / self.imageViewWidth.constant,
            self.scrollViewHeight.constant / self.imageViewHeight.constant)
        
        self.view.layoutIfNeeded()
        
        self.scrollView.zoomToRect(self.viewModel.cropRect!, animated: false)
        self.cropRectView.frame = self.scrollView.frame
        
        self.updateMaskLayerAnimated(false)
    }
    
    override func actionForLayer(layer: CALayer, forKey event: String) -> CAAction? {
        if event == "path" || event == "opacity" {
            let action = CABasicAnimation(keyPath: event)
            action.duration = CATransaction.animationDuration()
            action.timingFunction = CATransaction.animationTimingFunction()
            action.fromValue = layer.valueForKey(event)
            return action
        } else {
            return nil
        }
    }
    
    private func updateMaskLayerAnimated(animated:Bool) {
        let disableActions = CATransaction.disableActions()
        
        if animated == disableActions {
            CATransaction.setDisableActions(!animated)
        }
        
        self.maskLayer.frame = self.view.layer.bounds
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, self.maskLayer.bounds)
        CGPathAddRect(path, nil, self.view.convertRect(self.cropRectView.bounds, fromView: self.cropRectView))
        self.maskLayer.path = path
        
        if disableActions != CATransaction.disableActions() {
            CATransaction.setDisableActions(disableActions)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.imageView.image = self.viewModel.image
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
            self.maskLayer.opacity = 0.8
            self.cropRectView.alpha = 1
            self.toolbar.alpha = 1
        })
    }
    
    func pannedCropRectView(panGestureRecognizer:UIPanGestureRecognizer) {
        if cropPanMode == nil && panGestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        let pan = panGestureRecognizer.translationInView(self.view)
        
        if panGestureRecognizer.state == UIGestureRecognizerState.Began {
            self.cropRectOriginalFrame = self.cropRectView.frame
            
            let panStart = panGestureRecognizer.locationInView(self.cropRectView)
            
            let topLeftCorner = self.cropRectView.bounds.origin
            let bottomLeftCorner = CGPoint(x: topLeftCorner.x, y: topLeftCorner.y + self.cropRectView.bounds.height)
            let bottomRightCorner = CGPoint(x: bottomLeftCorner.x + self.cropRectView.bounds.width, y: bottomLeftCorner.y)
            let topRightCorner = CGPoint(x: bottomRightCorner.x, y: topLeftCorner.y)
            
            let leftEdgeDistance = pointLineDistance(panStart, linePoint1: topLeftCorner, linePoint2: bottomLeftCorner)
            let bottomEdgeDistance = pointLineDistance(panStart, linePoint1: bottomLeftCorner, linePoint2: bottomRightCorner)
            let rightEdgeDistance = pointLineDistance(panStart, linePoint1: bottomRightCorner, linePoint2: topRightCorner)
            let topEdgeDistance = pointLineDistance(panStart, linePoint1: topRightCorner, linePoint2: topLeftCorner)
            
            if leftEdgeDistance < 20 {
                if topEdgeDistance < 20 {
                    self.cropPanMode = CropPanMode.TopLeft
                } else if bottomEdgeDistance < 20 {
                    self.cropPanMode = CropPanMode.BottomLeft
                } else {
                    self.cropPanMode = CropPanMode.Left
                }
            } else if rightEdgeDistance < 20 {
                if topEdgeDistance < 20 {
                    self.cropPanMode = CropPanMode.TopRight
                } else if bottomEdgeDistance < 20 {
                    self.cropPanMode = CropPanMode.BottomRight
                } else {
                    self.cropPanMode = CropPanMode.Right
                }
            } else if topEdgeDistance < 20 {
                self.cropPanMode = CropPanMode.Top
            } else if bottomEdgeDistance < 20 {
                self.cropPanMode = CropPanMode.Bottom
            } else {
                self.cropPanMode = nil
            }
        
        } else if panGestureRecognizer.state == UIGestureRecognizerState.Changed {
            
            var cropRectFrame = self.cropRectOriginalFrame
            
            switch self.cropPanMode! {
            case .Top:
                cropRectFrame.origin.y += pan.y
                cropRectFrame.size.height -= pan.y
                
            case .Bottom:
                cropRectFrame.size.height += pan.y
                
            case .Left:
                cropRectFrame.origin.x += pan.x
                cropRectFrame.size.width -= pan.x
                
            case .Right:
                cropRectFrame.size.width += pan.x
                
            case .TopLeft:
                cropRectFrame.origin.y += pan.y
                cropRectFrame.size.height -= pan.y
                cropRectFrame.origin.x += pan.x
                cropRectFrame.size.width -= pan.x
                
            case .BottomLeft:
                cropRectFrame.size.height += pan.y
                cropRectFrame.origin.x += pan.x
                cropRectFrame.size.width -= pan.x
                
            case .TopRight:
                cropRectFrame.origin.y += pan.y
                cropRectFrame.size.height -= pan.y
                cropRectFrame.size.width += pan.x
                
            case .BottomRight:
                cropRectFrame.size.height += pan.y
                cropRectFrame.size.width += pan.x
            }
            
            let imageViewFrame = self.view.convertRect(self.imageView.bounds, fromView: self.imageView)
            self.cropRectView.frame = CGRectIntersection(cropRectFrame, imageViewFrame)
            
            self.updateMaskLayerAnimated(false)
            
        } else if panGestureRecognizer.state == UIGestureRecognizerState.Ended {
            var adjustedContentOffset = self.scrollView.contentOffset
            if self.cropPanMode == CropPanMode.Top {
                adjustedContentOffset.y += pan.y
            } else if self.cropPanMode == CropPanMode.Left {
                adjustedContentOffset.x += pan.x
            } else if self.cropPanMode == CropPanMode.TopLeft {
                adjustedContentOffset.x += pan.x
                adjustedContentOffset.y += pan.y
            } else if self.cropPanMode == CropPanMode.BottomLeft {
                adjustedContentOffset.x += pan.x
            } else if self.cropPanMode == CropPanMode.TopRight {
                adjustedContentOffset.y += pan.y
            }
            self.cropPanMode = nil
            
            let cropRect = self.imageView.convertRect(self.cropRectView.bounds, fromView: self.cropRectView)
            
            self.setScrollViewConstraintsForCropRect(cropRect)
            
            self.view.userInteractionEnabled = false
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                    CATransaction.setAnimationDuration(0.3)
                    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
                    
                    self.scrollView.frame = self.cropRectView.frame
                    self.scrollView.contentOffset = adjustedContentOffset
                    
                    self.view.layoutIfNeeded() // centers and resizes scrollView.frame and cropRectView.frame
                    
                    self.updateMaskLayerAnimated(true)
                    
                    self.scrollView.zoomToRect(cropRect, animated: false)
                }, completion: {
                    (completed) -> Void in
                    self.view.userInteractionEnabled = true
                })
            
            self.scrollView.minimumZoomScale = max(
                self.scrollViewWidth.constant / self.imageViewWidth.constant,
                self.scrollViewHeight.constant / self.imageViewHeight.constant)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        let cropRect = self.imageView.convertRect(self.cropRectView.bounds, fromView: self.cropRectView)
        self.viewModel.saveCropRect(cropRect)
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.viewModel.cancel()
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}