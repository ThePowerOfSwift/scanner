//
//  PagesViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class PagedCollectionView : UICollectionView {
    
    var currentPage: Int {
        get {
            return Int(round(self.contentOffset.x / self.bounds.width))
        }
        set {
            self.setCurrentPage(newValue, animated: false)
        }
    }
    
    func setCurrentPage(currentPage: Int, animated: Bool) {
        self.setContentOffset(CGPoint(x: self.bounds.width * CGFloat(currentPage), y: 0), animated: animated)
    }
    
    var flowLayout: UICollectionViewFlowLayout {
        get { return self.collectionViewLayout as! UICollectionViewFlowLayout }
    }
    
    override var bounds: CGRect {
        get { return super.bounds }
        set {
            let sizeChanged = newValue.size != self.bounds.size
            let currentPage = self.currentPage
            
            super.bounds = newValue
            
            if sizeChanged {
                self.flowLayout.itemSize = newValue.size
                self.currentPage = currentPage
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.pagingEnabled = true
        self.flowLayout.minimumInteritemSpacing = 0
        self.flowLayout.minimumLineSpacing = 0
        self.flowLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        self.flowLayout.sectionInset = UIEdgeInsetsZero
        self.flowLayout.headerReferenceSize = CGSizeZero
        self.flowLayout.footerReferenceSize = CGSizeZero
    }
}

class ImageZoomerScrollView : UIScrollView {
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        let view = self.delegate!.viewForZoomingInScrollView!(self)!
//        
//        if view.frame.width < self.bounds.width {
//            view.frame.origin.x = (self.bounds.width - view.frame.width) / 2
//        } else {
//            view.frame.origin.x = 0
//        }
//        
//        if view.frame.height < self.bounds.height {
//            view.frame.origin.y = (self.bounds.height - view.frame.height) / 2
//        } else {
//            view.frame.origin.y = 0
//        }
//    }
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
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        scrollView.scrollEnabled = scrollView.zoomScale != scrollView.minimumZoomScale
        let horizontalInset = max(0, self.scrollView.bounds.width - self.imageView.frame.width) / 2
        let verticalInset = max(0, self.scrollView.bounds.height - self.imageView.frame.height) / 2
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset);
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
    @IBOutlet weak var collectionView: PagedCollectionView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(observerToken)
    }
    
    private var visibleCell: PageCollectionViewCell? {
        get {
            if self.viewModel.pages.count > 0 {
                let indexPath = NSIndexPath(forItem: self.collectionView.currentPage, inSection: 0)
                return self.collectionView.cellForItemAtIndexPath(indexPath) as? PageCollectionViewCell
            } else {
                return nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = ViewModelFactory.sharedInstance.pagesViewModel()
        self.navigationItem.title = self.viewModel.documentTitle
        
        self.editButton.enabled = self.viewModel.pages.count > 0
        
        self.observerToken = NSNotificationCenter.defaultCenter().addObserverForName(
            PagesViewModel.ViewModelChangedNotification,
            object: self.viewModel,
            queue: nil) {
            [unowned self] (notification) -> Void in
                self.collectionView.reloadData()
                self.editButton.enabled = self.viewModel.pages.count > 0
                if let addedPages: AnyObject = notification.userInfo?[PagesViewModel.ViewModelChangedNotificationAddedPages] {
                    let addedPagesSet = addedPages as! Set<Page>
                    if addedPagesSet.count > 0 {
                        self.collectionView.currentPage = self.viewModel.pages.count - 1
                    }
                }
            }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let cell = self.visibleCell {
            cell.scrollView.contentOffset = CGPointZero
            cell.scrollView.zoomScale = cell.scrollView.minimumZoomScale
        }
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
        
        cell.scrollView.minimumZoomScale = min(
            (collectionView.bounds.width - 2*10) / thumbnail.size.width,
            collectionView.bounds.height / thumbnail.size.height)
        cell.scrollView.maximumZoomScale = 5 * cell.scrollView.minimumZoomScale
        cell.scrollView.zoomScale = cell.scrollView.minimumZoomScale
        let horizontalInset = max(0, (collectionView.bounds.width - 2*10) - thumbnail.size.width * cell.scrollView.zoomScale) / 2
        let verticalInset = max(0, collectionView.bounds.height - thumbnail.size.height * cell.scrollView.zoomScale) / 2
        cell.scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset)
        
        cell.scrollView.scrollEnabled = false
        
        return cell
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        self.viewModel.selectPageAtIndex(self.collectionView.currentPage)
        self.performSegueWithIdentifier("ShowPageSegue", sender: sender)
    }
}
