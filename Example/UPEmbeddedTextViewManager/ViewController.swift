//
//  ViewController.swift
//  UPEmbeddedTextView
//
//  Created by Martin Uribe on 4/5/15.
//  Copyright (c) 2015 up. All rights reserved.
//  
//  Disclaimer:
//  TEST VIEW CONTROLLER: Ideally, this view controller represents a common view
//  controller used by anyone who attempts to use this library. It is not and should not
//  however, be (a required) part of the library if possible.
//

import UIKit
import UPEmbeddedTextViewManager

class ViewController: UIViewController, UITableViewDataSource, UITextViewDelegate {

    var previousTextViewRect: CGSize!
    @IBOutlet weak var tableView: UITableView!
    var testText: NSString = "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    
    var testText2: NSString = "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    
    var testText3: NSString = "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    var testTexts: NSMutableArray!
    var tableViewManager: UPManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previousTextViewRect = CGSizeZero
        self.testTexts = [testText, testText2, testText3]
        self.tableViewManager = UPManager(delegate: self, tableView: tableView, defaults: nil)
        self.tableViewManager.startListeningForKeyboardEvents()
        self.tableView.estimatedRowHeight = 100.0;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("testCell", forIndexPath: indexPath) as? TestCellTableViewCell {
            let metadata = UPManagedTextViewMetadata(textView: cell.textView, heightConstraint: nil, enableAutomaticCollapse: true, collapsedHeightConstant: 125)
            tableViewManager.registerMetadata(metadata, indexPath: indexPath)
            
            if let testText = self.testTexts[indexPath.row] as? String{
                cell.textView.text = testText
            }
            
            return cell
        }
        let cell = UITableViewCell()
        return cell
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: (textView.tag-1), inSection: 0)) as? TestCellTableViewCell{
            if cell.textView == textView {
                self.testTexts[(textView.tag-1)] = cell.textView.text
            }
        }
    }
}

