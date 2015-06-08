//
//  UPManager.swift
//  UPEmbeddedTextView
//
//  Created by Adriana Pineda on 4/25/15.
//  Copyright (c) 2015 up. All rights reserved.
//

import UIKit

class UPTextViewSelection {
    var start: CGRect = CGRectZero
    var end: CGRect = CGRectZero
}

class UPManager: NSObject, UITextViewDelegate {
    
    var offScreenCells: NSMutableDictionary!
    weak var tableView: UITableView!
    let textViewSelection = UPTextViewSelection()
    var managedTextViewsMetaData = NSMutableDictionary()
    var delegate: UITextViewDelegate?
    
    let defaultTopScrollingOffset: CGFloat = CGFloat(30)
    let defaultBottomScrollingOffset: CGFloat = CGFloat(40)
    
    var topScrollingOffset:CGFloat = CGFloat(-1)
    var bottomScrollingOffset:CGFloat = CGFloat(-1)
    
    init(delegate:UITextViewDelegate?, tableView: UITableView) {
        super.init()
        if let initializedTableView = tableView as UITableView?{
            self.tableView = initializedTableView
        }
        else{
            fatalError("UPManager initialized without a valid tableView instance")
        }
        if let textViewDelegate = delegate as UITextViewDelegate?{
            self.delegate = textViewDelegate
        }
        self.offScreenCells = NSMutableDictionary()
        
        topScrollingOffset = defaultTopScrollingOffset
        bottomScrollingOffset = defaultBottomScrollingOffset
    }
    
    // Methods
    func configureTopScrollingOffset(newTopScrollingOffset: CGFloat) {
        
        if newTopScrollingOffset < 0 {
            self.topScrollingOffset = CGFloat(0)
        } else {
            self.topScrollingOffset = newTopScrollingOffset
        }
    }
    
    func configureBottomScrollingOffset(newBottomScrollingOffset: CGFloat) {
        
        if newBottomScrollingOffset < 0 {
            self.bottomScrollingOffset = CGFloat(0)
        } else {
            self.bottomScrollingOffset = newBottomScrollingOffset
        }
    }
    
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
        
        return size.height //+ absolutePaddingHeight
        
    }
    
    // Mark: -
    
    func updateTextViewZoomArea(textView: UITextView) {
        
        // Gets current selection in the coordinate space of the text view
        let selectionRange :UITextRange = textView.selectedTextRange!
        var selectionStartRect: CGRect = textView.caretRectForPosition(selectionRange.start)
        var selectionEndRect: CGRect = textView.caretRectForPosition(selectionRange.end)
        
        // Transforms current selection to the table view's coordinate space
        selectionStartRect = textView.convertRect(selectionStartRect, toView: self.tableView)
        selectionEndRect = textView.convertRect(selectionEndRect, toView: self.tableView)
        
        let visibleFrameInsets = self.tableView.scrollIndicatorInsets
        let visibleHeight:CGFloat = self.tableView.bounds.height - visibleFrameInsets.bottom
        
        let rectY:CGFloat = self.yCoordinateForEnclosingRectWithStartRect(selectionStartRect, endRect: selectionEndRect, visibleHeight: visibleHeight)
        
        if rectY >= 0 && !(selectionStartRect.origin.y == self.textViewSelection.start.origin.y && selectionEndRect.origin.y == self.textViewSelection.end.origin.y)
        {
            let enclosingRect: CGRect = CGRectMake(0,
                rectY,
                CGRectGetWidth(self.tableView.bounds),
                visibleHeight)
            
            UIView.animateWithDuration(0.2, delay:0, options:UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.tableView.scrollRectToVisible(enclosingRect, animated: false)
                }, completion:nil)
        }
        // TODO: WE MUST AVOID USING A STATIC STRUCT!!! There are serious issues because of that
        // TODO: WE MUST RESET the selection/start/end always after finishing editing..
        self.textViewSelection.start = selectionStartRect
        self.textViewSelection.end = selectionEndRect
    }
    
    func configureTopAndBottomScrollingOffsetsForVisibleHeight(visibleHeight:CGFloat) {
        
        if topScrollingOffset > (visibleHeight/4) {
            topScrollingOffset = floor(visibleHeight/4)
        }
        
        if bottomScrollingOffset > (visibleHeight/4) {
            bottomScrollingOffset = floor(visibleHeight/4)
        }
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
            configureTopAndBottomScrollingOffsetsForVisibleHeight(visibleHeight)
            // The |_| start of my current selection ends her|e|
            // Current end selection is scrolling towards the bottom
            if (endRect.origin.y > self.textViewSelection.end.origin.y && endRect.origin.y > contentOffsetY2 - bottomScrollingOffset)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
            // Current end selection is scrolling towards the top
            else if endRect.origin.y < self.textViewSelection.end.origin.y && endRect.origin.y < contentOffsetY + topScrollingOffset
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
            // Current start selection is scrolling towards the top
            else if (startRect.origin.y < self.textViewSelection.start.origin.y && startRect.origin.y < contentOffsetY + topScrollingOffset)
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
            // Current start selection is scrolling towards the bottom
            else if (startRect.origin.y > self.textViewSelection.start.origin.y && startRect.origin.y > contentOffsetY2 - bottomScrollingOffset)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
        }
        return rectY
    }
    
    func selectionJustBegan() ->Bool
    {
        return CGRectEqualToRect(self.textViewSelection.start, CGRectZero) || CGRectEqualToRect(self.textViewSelection.end, CGRectZero)
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
    
    // Mark: -
    
    func setManagedUPTextView(textView: UPEmbeddedTextView){
        if !self.isManagedUPTextView(textView){
            textView.upId = self.managedTextViewsMetaData.count
            let previousSize = CGSizeZero
            self.setManagedUPTextView(textView, previousSize: previousSize)
        }
    }
    
    func setManagedUPTextView(textView: UPEmbeddedTextView, previousSize:CGSize){
        self.managedTextViewsMetaData[textView.upId] = CGSizeCreateDictionaryRepresentation(previousSize)
    }
    
    private func isManagedUPTextView(textView: UPEmbeddedTextView) -> Bool{
        if (self.previousSizeDictionaryRepresentation(textView) as NSDictionary).count > 0{
            return true
        }
        return false
    }
    
    private func previousSizeDictionaryRepresentation(textView: UPEmbeddedTextView) -> CFDictionary{
        if let managedTextViewPreviousRect = self.managedTextViewsMetaData[textView.upId] as? NSDictionary{
            return managedTextViewPreviousRect
        }
        return [:]
    }
    
    private func previousSizeForUPTextView(textView: UPEmbeddedTextView) -> CGSize{
        var previousSize = CGSizeZero
        CGSizeMakeWithDictionaryRepresentation(self.previousSizeDictionaryRepresentation(textView), &previousSize)
        return previousSize
    }
    
    // Mark: - UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        if let delegate = self.delegate as UITextViewDelegate?{
            if delegate.respondsToSelector("textViewDidChange:"){
                delegate.textViewDidChange!(textView)
            }
        }
        if let upTextView = textView as? UPEmbeddedTextView{
            if self.isManagedUPTextView(upTextView){
                let currentSize: CGSize = textView.sizeThatFits(CGSizeMake(textView.frame.width, CGFloat.max));
                if (!CGSizeEqualToSize(currentSize, self.previousSizeForUPTextView(upTextView))) {
                    self.setManagedUPTextView(upTextView, previousSize: currentSize)
                    if !CGSizeEqualToSize(currentSize, CGSizeZero)
                    {
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                }
                
            }
        } 
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        self.updateTextViewZoomArea(textView)
        if let delegate = self.delegate as UITextViewDelegate?{
            if delegate.respondsToSelector("textViewDidChangeSelection:"){
                delegate.textViewDidChangeSelection!(textView)
            }
        }
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        var shouldBeginEditing = true
        if let delegate = self.delegate as UITextViewDelegate?{
            if delegate.respondsToSelector("textViewShouldBeginEditing:"){
                shouldBeginEditing = delegate.textViewShouldBeginEditing!(textView)
            }
        }
        if shouldBeginEditing{
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.textViewSelection.start = CGRectZero
            self.textViewSelection.end = CGRectZero
        }
        
        return shouldBeginEditing
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        if let delegate = self.delegate as UITextViewDelegate?{
            if delegate.respondsToSelector("textViewDidEndEditing:"){
                delegate.textViewDidEndEditing!(textView)
            }
        }
    }
    
    // Mark: - Forward Invocation
    
    override func respondsToSelector(aSelector: Selector) -> Bool {
        return super.respondsToSelector(aSelector) || self.delegate?.respondsToSelector(aSelector) == true
    }
    
    override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        if self.delegate?.respondsToSelector(aSelector)==true{
            return self.delegate
        }
        return super.forwardingTargetForSelector(aSelector)
    }
}
