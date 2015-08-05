//
//  ViewController.swift
//  Scanner
//
//  Created by Tamás Zahola on 15/07/15.
//  Copyright (c) 2015 Tamás Zahola. All rights reserved.
//

import UIKit

class DocumentListViewController:
UIViewController,
UITableViewDelegate,
UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel:DocumentListViewModel!
    private var observerToken:NSObjectProtocol!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(observerToken)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.observerToken = NSNotificationCenter.defaultCenter().addObserverForName(DocumentListViewModel.ViewModelChangedNotification, object: self.viewModel, queue: nil) {
            [unowned self] (notification) -> Void in
            self.tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.documents!.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        cell.textLabel!.text = self.viewModel.documents![indexPath.row].title
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.viewModel.deleteDocumentAtIndex(indexPath.row)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }

    @IBAction func addButtonPressed(sender: AnyObject) {
        let documentNamePrompt = UIAlertController(title: "Document Name", message: "Enter the document's name", preferredStyle: UIAlertControllerStyle.Alert)
        documentNamePrompt.addTextFieldWithConfigurationHandler(nil)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) {
            [unowned self] action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.Default) {
            [unowned self, unowned documentNamePrompt] action in
            let nameTextField = documentNamePrompt.textFields![0] as! UITextField
            self.viewModel.createDocumentWithName(nameTextField.text)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        documentNamePrompt.addAction(cancelAction)
        documentNamePrompt.addAction(addAction);
        
        self.presentViewController(documentNamePrompt, animated:true, completion:nil)
    }
}

