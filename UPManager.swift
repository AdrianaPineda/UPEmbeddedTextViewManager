//
//  UPManager.swift
//  UPEmbeddedTextView
//
//  Created by Adriana Pineda on 4/25/15.
//  Copyright (c) 2015 up. All rights reserved.
//

import UIKit

struct UPTextViewSelection {
    static var start: CGRect = CGRectZero
    static var end: CGRect = CGRectZero
}

class UPManager: NSObject {
    
    var offScreenCells: NSMutableDictionary!
    weak var tableView: UITableView!
    
    init(tableView: UITableView) {
        super.init()
        if let initializedTableView = tableView as UITableView?{
            self.tableView = initializedTableView
        }
        else{
            fatalError("UPManager initialized without a valid tableView instance")
        }
        self.offScreenCells = NSMutableDictionary()
    }
    
    // Methods
    
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
    func calculateHeightForConfiguredSizingCell(sizingCell: UITableViewCell, tableView: UITableView, indexPath: NSIndexPath, superViewBounds:CGRect,  textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String)->CGFloat {
        
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
                currentTextView.removeConstraint(currentTextView.textViewHeightConstraint)
                currentTextView.addConstraint(currentTextView.textViewHeightConstraint) //TODO: Might be added at the 'beginning'
                absolutePaddingHeight += currentTextView.getAbsolutePaddingHeight()
            }
            
        }
        
        var size: CGSize = sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        sizingCell.bounds = CGRectMake(sizingCell.bounds.origin.x, sizingCell.bounds.origin.y, CGRectGetWidth(superViewBounds), size.height)
        sizingCell.contentView.bounds = sizingCell.bounds
        
        sizingCell.setNeedsLayout()
        sizingCell.layoutIfNeeded()
        
        return size.height + absolutePaddingHeight

    }
    
    // Mark: - 
    
    func updateTextViewZoomArea(textView: UITextView){
        let selectionRange :UITextRange = textView.selectedTextRange!
        var selectionStartRect: CGRect = textView.caretRectForPosition(selectionRange.start)
        var selectionEndRect: CGRect = textView.caretRectForPosition(selectionRange.end)
        selectionStartRect = textView.convertRect(selectionStartRect, toView: self.tableView)
        selectionEndRect = textView.convertRect(selectionEndRect, toView: self.tableView)
        
        let visibleFrameInsets = self.tableView.scrollIndicatorInsets
        let visibleHeight:CGFloat = self.tableView.bounds.height - visibleFrameInsets.bottom
        
        let rectY:CGFloat = self.yCoordinateForEnclosingRectWithStartRect(selectionStartRect, endRect: selectionEndRect, visibleHeight: visibleHeight)
        
        if rectY >= 0 && !(selectionStartRect.origin.y == UPTextViewSelection.start.origin.y && selectionEndRect.origin.y == UPTextViewSelection.end.origin.y)
        {
            let enclosingRect: CGRect = CGRectMake(0,
                rectY,
                CGRectGetWidth(self.tableView.bounds),
                visibleHeight)
            
            UIView.animateWithDuration(0.2, delay:0, options:UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.tableView.scrollRectToVisible(enclosingRect, animated: false)
                }, completion:nil)
        }
        UPTextViewSelection.start = selectionStartRect
        UPTextViewSelection.end = selectionEndRect
    }
    
    func yCoordinateForEnclosingRectWithStartRect(startRect:CGRect, endRect:CGRect, visibleHeight:CGFloat) -> CGFloat
    {
        let contentOffsetY: CGFloat = self.tableView.contentOffset.y
        let contentOffsetY2: CGFloat = self.tableView.contentOffset.y + visibleHeight
        
        var rectY :CGFloat = -1
        if self.selectionJustBegan()
        {
            rectY = startRect.origin.y - (visibleHeight/2)
            rectY = rectY < 0 ? 0 : rectY
        }
        else
        {
            if (endRect.origin.y > UPTextViewSelection.end.origin.y && endRect.origin.y > contentOffsetY2 - 40)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
            else if endRect.origin.y < UPTextViewSelection.end.origin.y && endRect.origin.y < contentOffsetY + 30
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
            else if (startRect.origin.y < UPTextViewSelection.start.origin.y && startRect.origin.y < contentOffsetY + 30)
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
            else if (startRect.origin.y > UPTextViewSelection.start.origin.y && startRect.origin.y > contentOffsetY2 - 40)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
        }
        return rectY
    }
    
    func selectionJustBegan() ->Bool
    {
        return CGRectEqualToRect(UPTextViewSelection.start, CGRectZero) || CGRectEqualToRect(UPTextViewSelection.end, CGRectZero)
    }
    
    func heightForRowAtIndexPath(indexPath: NSIndexPath, reuseIdentifier: String, textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String) -> CGFloat {
        
        var superViewBounds = CGRectZero
        if let superview = self.tableView.superview {
            superViewBounds = superview.bounds;
        }
       
        var currentCellInstance: UITableViewCell?
        
        if let mappedCell = offScreenCells[reuseIdentifier] as? UITableViewCell {
            currentCellInstance = mappedCell
        } else {
            currentCellInstance = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? UITableViewCell
        }
        
        // TODO: Possible enhancement: Do not request the reuse identifier, but an actual Cell instance? It should be in a block!
        if currentCellInstance != nil{
            return self.calculateHeightForConfiguredSizingCell(currentCellInstance!, tableView:tableView, indexPath: indexPath, superViewBounds:superViewBounds, textForTextView:textForTextView)
        }
        
        return 0 // The cell couldn't be dequeued! Check the reuse identifier!
    }

}
