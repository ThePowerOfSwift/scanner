//
//  PagesViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class ImageZoomerScrollView : UIScrollView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let view = self.delegate!.viewForZoomingInScrollView!(self)!
        
        if view.frame.width < self.bounds.width {
            view.frame.origin.x = (self.bounds.width - view.frame.width) / 2
        }
        if view.frame.height < self.bounds.height {
            view.frame.origin.y = (self.bounds.height - view.frame.height) / 2
        }
    }
}

class ShowPageSegue: UIStoryboardSegue, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    override func perform() {
        let destination = self.destinationViewController as! UIViewController
        destination.transitioningDelegate = self
        self.sourceViewController.presentViewController(destination, animated:true, completion: {
            destination.transitioningDelegate = nil
        })
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let cell = (self.sourceViewController as! PagesViewController).visibleCell!
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let containerView = transitionContext.containerView()
        let fromFrame = containerView.convertRect(cell.imageView.bounds, fromView: cell.imageView)
        let toFrame = transitionContext.finalFrameForViewController(toViewController)
        
        let animatedBackgroundView = UIView()
        animatedBackgroundView.backgroundColor = toViewController.view.backgroundColor
        animatedBackgroundView.alpha = 0
        containerView.addSubview(animatedBackgroundView)
        animatedBackgroundView.frame = toFrame
        
        let animatedImageView = UIImageView(image: cell.imageView.image)
        animatedImageView.contentMode = UIViewContentMode.ScaleToFill
        containerView.addSubview(animatedImageView)
        animatedImageView.frame = fromFrame
        
        cell.imageView.hidden = true
        
        UIView.animateWithDuration(0.3, animations: {
            animatedBackgroundView.alpha = 1
            animatedImageView.frame = CGRectCenteredInRect(
                CGRectInset(toFrame, 60, 60),
                CGSizeScaledToFitSize(fromFrame.size, CGSize(width: toFrame.width - 120, height: toFrame.height - 120)))
        }, completion: {
            (completed) in
            
            cell.imageView.hidden = false
            
            animatedBackgroundView.removeFromSuperview()
            
            containerView.addSubview(toViewController.view)
            containerView.bringSubviewToFront(animatedImageView)
            toViewController.view.frame = toFrame
            transitionContext.completeTransition(true)
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                animatedImageView.alpha = 0
            }, completion: {
                (completed) in
                animatedImageView.removeFromSuperview()
            })
        })
    }
}

class PageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.layer.borderColor = UIColor.blueColor().CGColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
    
    override var selected:Bool {
        didSet {
            self.imageView.layer.borderWidth = selected ? 3 : 0
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}

class PagesViewController:
    UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource {

    private var viewModel:PagesViewModel!
    private var observerToken:NSObjectProtocol!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(observerToken)
    }
    
    private var visiblePageIndex: Int {
        get {
            return Int(round(self.collectionView.contentOffset.x / self.collectionView.bounds.width))
        }
    }
    
    private var visibleCell: PageCollectionViewCell? {
        get {
            if self.viewModel.pages.count > 0 {
                return
                    self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: self.visiblePageIndex, inSection: 0))
                    as? PageCollectionViewCell
            } else {
                return nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = ViewModelFactory.sharedInstance.pagesViewModel()
        self.navigationItem.title = self.viewModel.documentTitle
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        layout.sectionInset = UIEdgeInsetsZero
        layout.headerReferenceSize = CGSizeZero
        layout.footerReferenceSize = CGSizeZero
        
        self.editButton.enabled = self.viewModel.pages.count > 0
        
        self.observerToken = NSNotificationCenter.defaultCenter().addObserverForName(PagesViewModel.ViewModelChangedNotification, object: self.viewModel, queue: nil) {
            [unowned self] (notification) -> Void in
            self.collectionView.reloadData()
            self.editButton.enabled = self.viewModel.pages.count > 0
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.refreshCollectionViewItemSize()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.refreshCollectionViewItemSize()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let cell = self.visibleCell {
            cell.scrollView.contentOffset = CGPointZero
            cell.scrollView.zoomScale = cell.scrollView.minimumZoomScale
        }
    }
    
    private func refreshCollectionViewItemSize() {
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = self.collectionView.bounds.size
    }
    
    @IBAction func addPageButtonPressed(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.viewModel.createPageFromImage(image)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.pages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PageCell", forIndexPath: indexPath) as! PageCollectionViewCell
        let thumbnail = self.viewModel.pages[indexPath.row].thumbnail
        cell.imageView.image = thumbnail
        cell.imageWidth.constant = thumbnail.size.width
        cell.imageHeight.constant = thumbnail.size.height
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        cell.scrollView.minimumZoomScale = min(
            (layout.itemSize.width - 2*10) / thumbnail.size.width,
            layout.itemSize.height / thumbnail.size.height)
        cell.scrollView.zoomScale = cell.scrollView.minimumZoomScale
        cell.scrollView.maximumZoomScale = 5 * cell.scrollView.minimumZoomScale
        
        return cell
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        self.viewModel.selectPageAtIndex(self.visiblePageIndex)
        self.performSegueWithIdentifier("ShowPageSegue", sender: sender)
    }
}
