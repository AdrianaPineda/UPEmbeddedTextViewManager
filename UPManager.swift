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

class UPManagedTextViewMetaData {
    var previousRectDictionaryRepresentation: NSDictionary?
    var shouldCollapseHeightIfNeeded: Bool = true
    var reusableIdentifier: String!
}

class UPManager: NSObject, UITextViewDelegate {
    
    private var offScreenCells: NSMutableDictionary!
    private weak var tableView: UITableView!
    private let textViewSelection = UPTextViewSelection()
    private var managedTextViewsMetaData = NSMutableDictionary()
    private var managedTextViewsMapper = NSMutableDictionary()
    var delegate: UITextViewDelegate?
    
    private let defaultTopScrollingOffset: CGFloat = CGFloat(30)
    private let defaultBottomScrollingOffset: CGFloat = CGFloat(40)
    
    var topScrollingOffset:CGFloat = CGFloat(-1)
    var bottomScrollingOffset:CGFloat = CGFloat(-1)
    
    // MARK: - Lifecycle
    
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
    
    // MARK: - Public
    
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
        
        // Possible enhancement: Do not request the reuse identifier, but an actual Cell instance? It should be in a block!
        if currentCellInstance != nil{
            return self.calculateHeightForConfiguredSizingCell(currentCellInstance!, tableView:tableView, indexPath: indexPath, superViewBounds:superViewBounds, textForTextView:textForTextView)
        }
        
        return 0 // The cell couldn't be dequeued! Check the reuse identifier!
    }
    
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
        self.textViewSelection.start = selectionStartRect
        self.textViewSelection.end = selectionEndRect
    }
    
    func addManagedUPTextView(textView: UPEmbeddedTextView){
        if !self.isManagedUPTextView(textView){
            textView.upId = self.managedTextViewsMetaData.count
            let metaData = UPManagedTextViewMetaData()
            metaData.reusableIdentifier = textView.reuseIdentifier
            self.managedTextViewsMetaData[textView.upId] = metaData
            let previousSize = CGSizeZero
            self.setManagedUPTextView(textView, previousSize: previousSize)
        }
    }
    
    // MARK: Manager Settings
    
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
    
    func startListeningForKeyboardEvents(){
        self.stopListeningForKeyboardEvents()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func stopListeningForKeyboardEvents(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Private
    
    // MARK: Auxiliary Height Calculating Methods
    
    // Note: we use systemLayoutFittingSize as the technique for retrieving cell height
    // in order to offer compatibility with iOS 7. Once we discard iOS 7 we might use the
    // advantages of iOS 8
    private func calculateHeightForConfiguredSizingCell(sizingCell: UITableViewCell, tableView: UITableView, indexPath: NSIndexPath, superViewBounds:CGRect,  textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String)->CGFloat {
        
        var textViews = textViewsForCell(sizingCell)
        
        var absolutePaddingHeight:CGFloat = 0
        
        for textView in textViews {
            
            if let currentTextView = textView as? UPEmbeddedTextView {
                
                self.configureTextView(currentTextView, atIndexPath: indexPath, textForTextView:textForTextView)
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
    
    private func textViewsForCell(cell: UITableViewCell) -> NSArray {
        
        let textViews = NSMutableArray()
        
        findTextViewsOfView(cell.contentView, textViews: textViews)
        
        return textViews
    }
    
    // Do not allow UPEmbeddedTextViews to contain other UPEmbeddedTextViews
    private func findTextViewsOfView(view: UIView, textViews:NSMutableArray) {
        
        if let currentTextView = view as? UPEmbeddedTextView {
            self.addBaseManagedTextViewMapperIfNeededForTextView(currentTextView)
            textViews.addObject(currentTextView)
            
        } else {
            
            for currentView in view.subviews {
                
                findTextViewsOfView(currentView as! UIView, textViews: textViews)
            }
        }
        
    }
    
    private func configureTextView(textView: UPEmbeddedTextView, atIndexPath indexPath:NSIndexPath, textForTextView: (textView:UPEmbeddedTextView, indexPath:NSIndexPath) -> String) {
        
        textView.text = textForTextView(textView:textView, indexPath:indexPath)
        textView.textViewHeightConstraint.constant = self.sizeForTextView(textView, atIndexPath: indexPath).height
        textView.removeConstraint(textView.textViewHeightConstraint)
        textView.addConstraint(textView.textViewHeightConstraint) //Might be added at the 'beginning'
    }
    
    private func sizeForTextView(textView: UPEmbeddedTextView, atIndexPath indexPath: NSIndexPath) -> CGSize{
        var textViewSize = textView.sizeThatFits(CGSizeMake(CGRectGetWidth(self.tableView.bounds), CGFloat.max))
        if let metaData = self.metaDataForReuseIdentifier(textView.reuseIdentifier, indexPath: indexPath) as UPManagedTextViewMetaData?{
            if textView.enableAutomaticCollapse &&
                metaData.shouldCollapseHeightIfNeeded &&
                textViewSize.height > textView.collapsedHeightConstant{
                    textViewSize.height = textView.collapsedHeightConstant
                    self.removeChangingTextViewMapForReuseIdentifier(textView.reuseIdentifier, atIndexPath: indexPath)
            }
        }
        else if textView.enableAutomaticCollapse && textViewSize.height > textView.collapsedHeightConstant{
            textViewSize.height = textView.collapsedHeightConstant
        }
        return textViewSize
    }
    
    // MARK: Auxiliary Zoom Methods
    
    private func yCoordinateForEnclosingRectWithStartRect(startRect:CGRect, endRect:CGRect, visibleHeight:CGFloat) -> CGFloat
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
    
    private func configureTopAndBottomScrollingOffsetsForVisibleHeight(visibleHeight:CGFloat) {
        
        if topScrollingOffset > (visibleHeight/4) {
            topScrollingOffset = floor(visibleHeight/4)
        }
        
        if bottomScrollingOffset > (visibleHeight/4) {
            bottomScrollingOffset = floor(visibleHeight/4)
        }
    }
    
    private func selectionJustBegan() -> Bool
    {
        return CGRectEqualToRect(self.textViewSelection.start, CGRectZero) || CGRectEqualToRect(self.textViewSelection.end, CGRectZero)
    }
    
    // MARK: Managed UPEmbeddedTextView and Meta Data auxiliary methods
    
    private func setManagedUPTextView(textView: UPEmbeddedTextView, previousSize:CGSize){
        if let metaData = self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData?{
            metaData.previousRectDictionaryRepresentation = CGSizeCreateDictionaryRepresentation(previousSize)
        }
    }
    
    private func isManagedUPTextView(textView: UPEmbeddedTextView) -> Bool{
        if let metaData = self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData?{
            return true
        }
        return false
    }
    
    private func metaDataForManagedTextView(textView: UPEmbeddedTextView) -> UPManagedTextViewMetaData?{
        return self.metaDataAtIndex(textView.upId)
    }
    
    private func metaDataForReuseIdentifier(reuseId: String, indexPath: NSIndexPath) -> UPManagedTextViewMetaData?{
        if let indexPaths = self.managedTextViewsMapper[reuseId] as? NSMutableDictionary{
            if let upId = indexPaths[NSIndexPath(forRow: indexPath.row, inSection: indexPath.section)] as? NSInteger{
                return self.metaDataAtIndex(upId)
            }
        }
        return nil
    }
    
    private func metaDataAtIndex(index: Int) -> UPManagedTextViewMetaData?{
        return self.managedTextViewsMetaData[index] as? UPManagedTextViewMetaData
    }
    
    private func addBaseManagedTextViewMapperIfNeededForTextView(textView: UPEmbeddedTextView){
        if self.managedTextViewsMapper[textView.reuseIdentifier] == nil{
            // Gotta add this reuse identifier
            self.managedTextViewsMapper[textView.reuseIdentifier] = NSMutableDictionary()
        }
    }
    
    private func enqueueChangingTextView(textView: UPEmbeddedTextView!, atIndexPath indexPath: NSIndexPath!){
        if let indexPaths = self.managedTextViewsMapper[textView.reuseIdentifier] as? NSMutableDictionary {
            indexPaths.setObject(textView.upId, forKey: NSIndexPath(forRow: indexPath.row, inSection: indexPath.section))
        }
    }
    
    private func removeChangingTextViewMapForReuseIdentifier(reuseId: String, atIndexPath indexPath:NSIndexPath){
        if let indexPaths = self.managedTextViewsMapper[reuseId] as? NSMutableDictionary{
            indexPaths.removeObjectForKey(NSIndexPath(forRow: indexPath.row, inSection: indexPath.section))
        }
    }
    
    // MARK: - UITextViewDelegate
    
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
        self.textView(textView, shouldCollapseIfNeeded: false)
        if shouldBeginEditing{
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.textViewSelection.start = CGRectZero
            self.textViewSelection.end = CGRectZero
        }
        
        return shouldBeginEditing
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.textView(textView, shouldCollapseIfNeeded: true)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        if let delegate = self.delegate as UITextViewDelegate?{
            if delegate.respondsToSelector("textViewDidEndEditing:"){
                delegate.textViewDidEndEditing!(textView)
            }
        }
    }
    
    // MARK: - Private Utilities
    
    private func textView(textView: UITextView, shouldCollapseIfNeeded shouldCollapse:Bool){
        if let upTextView = textView as? UPEmbeddedTextView{
            if upTextView.enableAutomaticCollapse{
                if let metaData = self.metaDataForManagedTextView(upTextView) as UPManagedTextViewMetaData?{
                    let center = upTextView.center
                    let rootViewPoint = upTextView.superview!.convertPoint(center, toView:self.tableView)
                    if let indexPath = self.tableView.indexPathForRowAtPoint(rootViewPoint) as NSIndexPath?{
                        self.enqueueChangingTextView(upTextView, atIndexPath: indexPath)
                    }
                    metaData.shouldCollapseHeightIfNeeded = shouldCollapse
                }
            }
        }
    }
    
    private func previousSizeDictionaryRepresentation(textView: UPEmbeddedTextView) -> CFDictionary{
        if let metaData = self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData?{
            if let managedTextViewPreviousRect = metaData.previousRectDictionaryRepresentation as NSDictionary?{
                return managedTextViewPreviousRect
            }
        }
        return [:]
    }
    
    private func previousSizeForUPTextView(textView: UPEmbeddedTextView) -> CGSize{
        var previousSize = CGSizeZero
        CGSizeMakeWithDictionaryRepresentation(self.previousSizeDictionaryRepresentation(textView), &previousSize)
        return previousSize
    }
    
    // MARK: - Forward Invocation
    
    override func respondsToSelector(aSelector: Selector) -> Bool {
        return super.respondsToSelector(aSelector) || self.delegate?.respondsToSelector(aSelector) == true
    }
    
    override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        if self.delegate?.respondsToSelector(aSelector)==true{
            return self.delegate
        }
        return super.forwardingTargetForSelector(aSelector)
    }
    
    // MARK: - Keyboard Observer
    
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
    
    deinit{
        self.stopListeningForKeyboardEvents()
    }
}
