//
//  UITableView+UP.swift
//  UPEmbeddedTextView
//
//  Created by Martin Uribe on 4/5/15.
//  Copyright (c) 2015 up. All rights reserved.
//

import UIKit

struct TextViewSelection {
    static var start: CGRect = CGRectZero
    static var end: CGRect = CGRectZero
}

extension UITableView {

    func updateTextViewZoomArea(textView: UITextView){
        let selectionRange :UITextRange = textView.selectedTextRange!
        var selectionStartRect: CGRect = textView.caretRectForPosition(selectionRange.start)
        var selectionEndRect: CGRect = textView.caretRectForPosition(selectionRange.end)
        selectionStartRect = textView.convertRect(selectionStartRect, toView: self)
        selectionEndRect = textView.convertRect(selectionEndRect, toView: self)
        
        let visibleFrameInsets = self.scrollIndicatorInsets
        let visibleHeight:CGFloat = self.bounds.height - visibleFrameInsets.bottom
        
        let rectY:CGFloat = self.yCoordinateForEnclosingRectWithStartRect(selectionStartRect, endRect: selectionEndRect, visibleHeight: visibleHeight)
        
        if rectY >= 0 && !(selectionStartRect.origin.y == TextViewSelection.start.origin.y && selectionEndRect.origin.y == TextViewSelection.end.origin.y)
        {
            let enclosingRect: CGRect = CGRectMake(0,
                rectY,
                CGRectGetWidth(self.bounds),
                visibleHeight)
            
            UIView.animateWithDuration(0.2, delay:0, options:UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.scrollRectToVisible(enclosingRect, animated: false)
                }, completion:nil)
        }
        TextViewSelection.start = selectionStartRect
        TextViewSelection.end = selectionEndRect
    }
    
    func yCoordinateForEnclosingRectWithStartRect(startRect:CGRect, endRect:CGRect, visibleHeight:CGFloat) -> CGFloat
    {
        let contentOffsetY: CGFloat = self.contentOffset.y
        let contentOffsetY2: CGFloat = self.contentOffset.y + visibleHeight
        
        var rectY :CGFloat = -1
        if self.selectionJustBegan()
        {
            rectY = startRect.origin.y - (visibleHeight/2)
            rectY = rectY < 0 ? 0 : rectY
        }
        else
        {
            if (endRect.origin.y > TextViewSelection.end.origin.y && endRect.origin.y > contentOffsetY2 - 40)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
            else if endRect.origin.y < TextViewSelection.end.origin.y && endRect.origin.y < contentOffsetY + 30
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
            else if (startRect.origin.y < TextViewSelection.start.origin.y && startRect.origin.y < contentOffsetY + 30)
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
            else if (startRect.origin.y > TextViewSelection.start.origin.y && startRect.origin.y > contentOffsetY2 - 40)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
        }
        return rectY
    }
    
    func selectionJustBegan() ->Bool
    {
        return CGRectEqualToRect(TextViewSelection.start, CGRectZero) || CGRectEqualToRect(TextViewSelection.end, CGRectZero)
    }
    
    func heightForRowAtIndexPath(indexPath: NSIndexPath, reuseIdentifier: String, textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String) -> CGFloat {
        
        let upManager = UPManager()
        var superViewBounds = CGRectZero
        if let superview = self.superview {
            superViewBounds = superview.bounds;
        }
        return upManager.tableView(self, heightForRowAtIndexPath: indexPath, reuseIdentifier: reuseIdentifier, superViewBounds:superViewBounds, textForTextView:textForTextView)
    }
}
