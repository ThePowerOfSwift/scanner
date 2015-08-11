//
//  PagesViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class ShowPageSegue: UIStoryboardSegue, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    var cell:PageCollectionViewCell!
    
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
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let containerView = transitionContext.containerView()
        let fromFrame = containerView.convertRect(self.cell.imageView.bounds, fromView: self.cell)
        let toFrame = transitionContext.finalFrameForViewController(toViewController)
        
        let animatedImageView = UIImageView(image: self.cell.imageView.image)
        animatedImageView.contentMode = UIViewContentMode.ScaleAspectFill
        containerView.addSubview(animatedImageView)
        animatedImageView.frame = fromFrame
        
        UIView.animateWithDuration(0.3, animations: {
            animatedImageView.frame = toFrame
        }, completion: {
            (completed) in
            
            animatedImageView.removeFromSuperview()
            
            containerView.addSubview(toViewController.view)
            toViewController.view.frame = toFrame
            
            transitionContext.completeTransition(true)
        })
    }
}

class PageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(observerToken)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = ViewModelFactory.sharedInstance.pagesViewModel()
        self.navigationItem.title = self.viewModel.documentTitle
        
        self.observerToken = NSNotificationCenter.defaultCenter().addObserverForName(PagesViewModel.ViewModelChangedNotification, object: self.viewModel, queue: nil) {
            [unowned self] (notification) -> Void in
            self.collectionView.reloadData()
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        self.viewModel.selectPageAtIndex(indexPath.row)
        self.performSegueWithIdentifier("ShowPageSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.pages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PageCell", forIndexPath: indexPath) as! PageCollectionViewCell
        cell.pageNumberLabel.text = "\(indexPath.row + 1)"
        cell.imageView.image = self.viewModel.pages[indexPath.row].thumbnail
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPageSegue" {
            let segue = segue as! ShowPageSegue
            segue.cell = sender as! PageCollectionViewCell
        }
    }
}
