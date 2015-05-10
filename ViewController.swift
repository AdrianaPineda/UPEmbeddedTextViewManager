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

// EPIC: Try to reduce the amount of preparation the client requires in order to begin
// using the TextView API. For example the Keyboard delegation, the current properties
// being used by this controller, the cell's height calculation and the delegate methods
// of UITextView. We should focus in making the life easier for those using our library,
// not making them spend 4 hours trying to understand how to set up everything!

class ViewController: UIViewController, UITableViewDataSource, UITextViewDelegate {

    // TODO: How to avoid client requiring all these properties??
    var instance: TestCellTableViewCell? = nil
    var previousTextViewRect: CGSize!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    var testText: NSString = "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    
    var testText2: NSString = "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    
    var testText3: NSString = "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previousTextViewRect = CGSizeZero
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    func keyboardWillShow(notification: NSNotification)
    {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            var contentInsets = self.tableView.contentInset
            contentInsets = UIEdgeInsets(top: contentInsets.top, left: contentInsets.left, bottom: keyboardSize.height + UIApplication.sharedApplication().statusBarFrame.size.height, right: contentInsets.right)
            
            if keyboardSize.height > 0
            {
                self.tableView.contentInset = contentInsets
                self.tableView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        var contentInsets = self.tableView.contentInset
        contentInsets = UIEdgeInsets(top: contentInsets.top, left: contentInsets.left, bottom: 0, right: contentInsets.right)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 && (indexPath.row == 0 || indexPath.row == 1 || indexPath.row == 2) {
            
            return self.tableView.heightForRowAtIndexPath(indexPath, reuseIdentifier: "testCell", textForTextView:{ (textView, indexPath) -> String in
                
                if indexPath.row == 0 {
                    return self.testText as String
                } else if indexPath.row == 1 {
                    return self.testText2 as String
                } else {
                    return self.testText3 as String
                }
            })
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCellWithIdentifier("testCell", forIndexPath: indexPath) as? TestCellTableViewCell{
            cell.textView.delegate = self
            
            if indexPath.row == 0 {
                cell.textView.text = self.testText as String
            } else if indexPath.row == 1 {
                cell.textView.text = self.testText2 as String
            } else {
                cell.textView.text = self.testText3 as String
            }
            
            return cell
        }
        let cell = UITableViewCell()
        return cell
    }
    
    // MARK: - UITableViewDataSource helpers
    // TODO: Need to find a way to expose all these methods! i.e avoid the
    // client setting them if possible
    
    // This one might be client-configured
    func configureCell(sizingCell:TestCellTableViewCell, atIndexPath indexPath:NSIndexPath)
    {
        if indexPath.row == 0 {
            sizingCell.textView.text = self.testText as String
        } else if indexPath.row == 1{
            sizingCell.textView.text = self.testText2 as String
        } else {
            sizingCell.textView.text = self.testText3 as String
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        // TODO: Obviously we cannot expect to have a property textView. This must be scalable and
        // abstract!
        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? TestCellTableViewCell{
            if cell.textView == textView{
                self.testText = cell.textView.text
                let currentSize: CGSize = textView.sizeThatFits(CGSizeMake(textView.frame.width, CGFloat.max));
                // Check if the height really requires changing and a tableView update is needed
                if (!CGSizeEqualToSize(currentSize, self.previousTextViewRect) ) {
                    self.previousTextViewRect = currentSize;
                    if !CGSizeEqualToSize(self.previousTextViewRect, CGSizeZero)
                    {
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                }
            }
        }
        
        if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as? TestCellTableViewCell{
            if cell.textView == textView{
                self.testText = cell.textView.text
                let currentSize: CGSize = textView.sizeThatFits(CGSizeMake(textView.frame.width, CGFloat.max));
                // Check if the height really requires changing and a tableView update is needed
                if (!CGSizeEqualToSize(currentSize, self.previousTextViewRect) ) {
                    self.previousTextViewRect = currentSize;
                    if !CGSizeEqualToSize(self.previousTextViewRect, CGSizeZero)
                    {
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                }
            }
        }
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        self.tableView.updateTextViewZoomArea(textView)
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        // TODO: A nice to have: The user might choose to expand textView here
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        TextViewSelection.start = CGRectZero
        TextViewSelection.end = CGRectZero
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        // TODO: A nice to have: The user might choose to collapse textView here
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

}

