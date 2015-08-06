//
//  PagesViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 06/08/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class PageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.layer.cornerRadius = 3
        self.imageView.layer.masksToBounds = true
    }
    
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
}
