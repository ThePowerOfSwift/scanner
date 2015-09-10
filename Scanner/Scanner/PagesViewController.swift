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
            return saturate(
                Int(round(self.contentOffset.x / (self.flowLayout.itemSize.width + self.flowLayout.minimumLineSpacing))),
                min: 0,
                max: self.numberOfItemsInSection(0) - 1)
        }
        
        set {
            self.setCurrentPage(newValue, animated: false)
        }
    }
    
    func setCurrentPage(currentPage: Int, animated: Bool) {
        if currentPage >= 0 && currentPage <= self.numberOfItemsInSection(0) - 1 {
            self.scrollToItemAtIndexPath(
                NSIndexPath(forItem: currentPage, inSection: 0),
                atScrollPosition: UICollectionViewScrollPosition.Left,
                animated: animated)
        }
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
}

class ImageZoomerScrollView : UIScrollView {}

class ShowPageSegue: UIStoryboardSegue, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    override func perform() {
        let destination = self.destinationViewController 
        destination.transitioningDelegate = self
        self.sourceViewController.presentViewController(destination, animated:true, completion: {
            destination.transitioningDelegate = nil
        })
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let cell = (self.sourceViewController as! PagesViewController).visibleCell!
        
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let containerView = transitionContext.containerView()!
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
                size: CGSizeScaledToFitSize(fromFrame.size, sizeToFit: CGSize(width: toFrame.width - 120, height: toFrame.height - 120)))
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

protocol PageCollectionViewCellDelegate: class {
    func cellWillBeginDragging(cell: PageCollectionViewCell)
    func cellDidEndDragging(cell: PageCollectionViewCell, willDecelerate: Bool)
    func cellDidEndDecelerating(cell: PageCollectionViewCell)
    func cellWillBeginZooming(cell: PageCollectionViewCell)
    func cellDidEndZooming(cell: PageCollectionViewCell)
}

class PageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    weak var delegate: PageCollectionViewCellDelegate? = nil
    
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
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.delegate?.cellWillBeginDragging(self)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.delegate?.cellDidEndDragging(self, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.delegate?.cellDidEndDecelerating(self)
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        self.delegate?.cellWillBeginZooming(self)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        self.delegate?.cellDidEndZooming(self)
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

class PagesCollectionView: UICollectionView {
    var currentPage: Int {
        get {
            return saturate(
                Int(round(self.contentOffset.x / (self.flowLayout.itemSize.width + self.flowLayout.minimumLineSpacing))),
                min: 0,
                max: self.numberOfItemsInSection(0) - 1)
        }
        
        set {
            self.setCurrentPage(newValue, animated: false)
        }
    }
    
    func setCurrentPage(currentPage: Int, animated: Bool) {
        if currentPage >= 0 && currentPage <= self.numberOfItemsInSection(0) - 1 {
            self.scrollToItemAtIndexPath(
                NSIndexPath(forItem: currentPage, inSection: 0),
                atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally,
                animated: animated)
        }
    }
    
    override var bounds:CGRect {
        get { return super.bounds }
        set {
            let sizeChanged = super.bounds.size != newValue.size
            
            super.bounds = newValue
            
            if sizeChanged {
                let boundsSize = self.bounds.size
                let itemSize = min(boundsSize.width, boundsSize.height)
                self.flowLayout.itemSize = CGSizeMakeSquare(itemSize)
                self.flowLayout.sectionInset = UIEdgeInsets(
                    top: (boundsSize.height - itemSize) / 2,
                    left: (boundsSize.width - itemSize) / 2,
                    bottom: (boundsSize.height - itemSize) / 2,
                    right: (boundsSize.width - itemSize) / 2)
            }
        }
    }
    
    var flowLayout: UICollectionViewFlowLayout {
        get { return self.collectionViewLayout as! UICollectionViewFlowLayout }
    }
}

class MiniPageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
    }
}

class PagesViewController:
    UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    PageCollectionViewCellDelegate {

    private var viewModel:PagesViewModel!
    private var observerToken:NSObjectProtocol!
    @IBOutlet weak var collectionView: PagedCollectionView!
    @IBOutlet weak var pagesCollectionView: PagesCollectionView!
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
                self.pagesCollectionView.reloadData()
                self.editButton.enabled = self.viewModel.pages.count > 0
                if let addedPages: AnyObject = notification.userInfo?[PagesViewModel.ViewModelChangedNotificationAddedPages] {
                    let addedPagesSet = addedPages as! Set<Page>
                    if addedPagesSet.count > 0 {
                        self.collectionView.currentPage = self.viewModel.pages.count - 1
                        self.pagesCollectionView.currentPage = self.viewModel.pages.count - 1
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
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PageCell", forIndexPath: indexPath)
                as! PageCollectionViewCell
            let thumbnail = self.viewModel.pages[indexPath.row].thumbnail
            cell.imageView.image = thumbnail
            cell.imageWidth.constant = thumbnail.size.width
            cell.imageHeight.constant = thumbnail.size.height
            
            cell.scrollView.minimumZoomScale = min(
                (collectionView.bounds.width - 2*10) / thumbnail.size.width,
                collectionView.bounds.height / thumbnail.size.height)
            cell.scrollView.maximumZoomScale = 5 * cell.scrollView.minimumZoomScale
            cell.scrollView.zoomScale = cell.scrollView.minimumZoomScale
            let horizontalInset:CGFloat = max(0, (collectionView.bounds.width - 2*10) - thumbnail.size.width * cell.scrollView.zoomScale) / 2
            let verticalInset:CGFloat = max(0, collectionView.bounds.height - thumbnail.size.height * cell.scrollView.zoomScale) / 2
            cell.scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset)
            
            cell.scrollView.scrollEnabled = false
            cell.delegate = self
            
            return cell
        } else if collectionView == self.pagesCollectionView {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MiniPageCell", forIndexPath: indexPath)
                as! MiniPageCollectionViewCell
            cell.imageView.image = self.viewModel.pages[indexPath.row].thumbnail
            return cell
        } else {
            assertionFailure("Unknown collectionView: \(collectionView)")
            abort()
        }
    }
    
    func cellWillBeginDragging(cell: PageCollectionViewCell) {
        self.pagesCollectionView.panGestureRecognizer.enabled = false
    }
    
    func cellDidEndDragging(cell: PageCollectionViewCell, willDecelerate: Bool) {
        self.pagesCollectionView.panGestureRecognizer.enabled = !willDecelerate
    }
    
    func cellDidEndDecelerating(cell: PageCollectionViewCell) {
        self.pagesCollectionView.panGestureRecognizer.enabled = true
    }
    
    func cellWillBeginZooming(cell: PageCollectionViewCell) {
        self.pagesCollectionView.panGestureRecognizer.enabled = false
    }
    
    func cellDidEndZooming(cell: PageCollectionViewCell) {
        self.pagesCollectionView.panGestureRecognizer.enabled = !cell.scrollView.dragging
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        let collectionView = scrollView as! UICollectionView
        if collectionView == self.collectionView {
            self.pagesCollectionView.panGestureRecognizer.enabled = false
        } else if collectionView == self.pagesCollectionView {
            self.collectionView.panGestureRecognizer.enabled = false
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let collectionView = scrollView as! UICollectionView
        if collectionView == self.collectionView {
            self.pagesCollectionView.panGestureRecognizer.enabled = !decelerate
        } else if collectionView == self.pagesCollectionView {
            self.collectionView.panGestureRecognizer.enabled = !decelerate
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let collectionView = scrollView as! UICollectionView
        if collectionView == self.collectionView {
            self.pagesCollectionView.panGestureRecognizer.enabled = true
        } else if collectionView == self.pagesCollectionView {
            self.collectionView.panGestureRecognizer.enabled = true
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let collectionView = scrollView as! UICollectionView
        if collectionView == self.collectionView {
            if self.collectionView.panGestureRecognizer.enabled {
                self.pagesCollectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x / self.collectionView.flowLayout.itemSize.width * self.pagesCollectionView.flowLayout.itemSize.width, y: 0)
            }
        } else if collectionView == self.pagesCollectionView {
            if self.pagesCollectionView.panGestureRecognizer.enabled {
                self.collectionView.currentPage = self.pagesCollectionView.currentPage
            }
        }
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        self.viewModel.selectPageAtIndex(self.collectionView.currentPage)
        self.performSegueWithIdentifier("ShowPageSegue", sender: sender)
    }
}
