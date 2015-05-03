//
//  UPManager.swift
//  UPEmbeddedTextView
//
//  Created by Adriana Pineda on 4/25/15.
//  Copyright (c) 2015 up. All rights reserved.
//

import UIKit

class UPManager: NSObject {
    
    var offScreenCells: NSMutableDictionary!
    
    override init() {
        
        super.init()
        
        self.offScreenCells = NSMutableDictionary()
    }
    
//    class var sharedInstance: UPManager {
//        
//        struct Static {
//            static var onceToken: dispatch_once_t = 0
//            static var instance: UPManager? = nil
//        }
//        
//        dispatch_once(&Static.onceToken) {
//            Static.instance = UPManager()
//            Static.instance?.offScreenCells = NSMutableDictionary()
//        }
//        
//        return Static.instance!
//    }
    
    // Methods
    
    // Return the height for the row at index path
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath, reuseIdentifier: String, textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String) -> CGFloat {
        
        var currentCellInstance: UITableViewCell?
        
        if let mappedCell = offScreenCells[reuseIdentifier] as? UITableViewCell {
            
            currentCellInstance = mappedCell
            
        } else {
            
            currentCellInstance = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? UITableViewCell
            
            if currentCellInstance != nil  {
                
                currentCellInstance!.addConstraint(NSLayoutConstraint(item: currentCellInstance!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: CGRectGetWidth(tableView.bounds)))
            }
        }
        
//        self.configureCell(currentCellInstance!, atIndexPath: indexPath)
        return self.calculateHeightForConfiguredSizingCell(currentCellInstance!, tableView:tableView, indexPath: indexPath, textForTextView:textForTextView)
    }
    
    // This one might be client-configured
//    func configureCell(sizingCell:UITableViewCell, atIndexPath indexPath:NSIndexPath)
//    {
//        
//        //UPEmbeddedTextViews should already have text
//        
////        if indexPath.row == 0 {
////            sizingCell.textView.text = self.testText as String
////        } else {
////            sizingCell.textView.text = self.testText2 as String
////        }
//
//    }

    
    func configureTextView(textView: UPEmbeddedTextView, atIndexPath indexPath:NSIndexPath, textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String) {
        
        textView.text = textForTextView(textView:textView, indexPath:indexPath)
        
    }
    
    func textViewsForCell(cell: UITableViewCell) -> NSArray {
        
        let textViews = NSMutableArray()
        
        findTextViewsOfView(cell.contentView, textViews: textViews)
        
        return textViews
    }
    
    // Do not allow UPEmbeddedTextViews to contain other UPEmbeddedTextViews
    func findTextViewsOfView(view: UIView, textViews:NSMutableArray) {
        
        if let currentTextView = view as? UPEmbeddedTextView {
            
            textViews.addObject(currentTextView)
            
        } else {
         
            for currentView in view.subviews {
                
                findTextViewsOfView(currentView as! UIView, textViews: textViews)
            }
        }
        
    }
    
    // Note: we use systemLayoutFittingSize as the technique for retrieving cell height
    // in order to offer compatibility with iOS 7. Once we discard iOS 7 we might use the
    // advantages of iOS 8
    func calculateHeightForConfiguredSizingCell(sizingCell: UITableViewCell, tableView: UITableView, indexPath: NSIndexPath, textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String)->CGFloat {
        
        // TODO: Need to find a way to update the frame with the EXACT required height, so as
        // to avoid autolayout warnings for assigning the height constraint's constant to a
        // value that is greater than the current cell height!
        
        var textViews = textViewsForCell(sizingCell)
        
        var absolutePaddingHeight:CGFloat = 0
        
        for textView in textViews {
         
            if let currentTextView = textView as? UPEmbeddedTextView {
                
                self.configureTextView(currentTextView, atIndexPath: indexPath, textForTextView:textForTextView)
                
                let textViewSize:CGSize = currentTextView.sizeThatFits(CGSizeMake(CGRectGetWidth(tableView.bounds), CGFloat.max))
                currentTextView.textViewHeightConstraint.constant = textViewSize.height
                
                absolutePaddingHeight += currentTextView.getAbsolutePaddingHeight()
            }
            
        }
        
        sizingCell.setNeedsLayout()
        sizingCell.layoutIfNeeded()
        
        var size: CGSize = sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        return size.height + absolutePaddingHeight

    }

}
