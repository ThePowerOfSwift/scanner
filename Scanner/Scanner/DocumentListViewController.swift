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
UITableViewDataSource,
ViewModelObserver {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel:DocumentListViewModel!
    weak var viewModelObserverToken:ViewModel.ObserverToken!
    
    deinit {
        self.viewModel.removeObserver(self.viewModelObserverToken)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModelObserverToken = self.viewModel.addObserver(self)
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
    
    func viewModelChanged(viewModel: ViewModel) {
        self.tableView.reloadData()
    }
}

