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
    
    private var viewModel:DocumentListViewModel!
    private var observerToken:NSObjectProtocol!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(observerToken)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = ViewModelFactory.sharedInstance.documentListViewModel()
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        return [
            UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: {
                [unowned self] (action, indexPath) -> Void in
                self.viewModel.deleteDocumentAtIndex(indexPath.row)
            }),
            UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Rename", handler: {
                [unowned self] (action, indexPath) -> Void in
                self.tableView.setEditing(false, animated: true)
                self.renameDocumentAtIndex(indexPath.row)
            })
        ]
    }
    
    private func renameDocumentAtIndex(index:Int) {
        
        let renamePrompt = UIAlertController(title: "Rename Document", message: "Enter the new title", preferredStyle: UIAlertControllerStyle.Alert)
        renamePrompt.addTextFieldWithConfigurationHandler {
            (let textField) in
            textField.text = self.viewModel.documents![index].title
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) {
            [unowned self] action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let addAction = UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default) {
            [unowned self, unowned renamePrompt] action in
            let nameTextField = renamePrompt.textFields![0] as! UITextField
            self.viewModel.renameDocumentAtIndex(index, newTitle:nameTextField.text)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        renamePrompt.addAction(cancelAction)
        renamePrompt.addAction(addAction)
        
        self.presentViewController(renamePrompt, animated:true, completion:nil)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.viewModel.didSelectDocumentAtIndex(indexPath.row)
        self.performSegueWithIdentifier("ShowPagesSegue", sender: self)
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
        documentNamePrompt.addAction(addAction)
        
        self.presentViewController(documentNamePrompt, animated:true, completion:nil)
    }
}

