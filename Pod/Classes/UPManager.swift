//
//  UPManager.swift
//  UPEmbeddedTextView
//
//  Created by Adriana Pineda on 4/25/15.
//  Copyright (c) 2015 up. All rights reserved.
//

private class UPTextViewSelection {
    var start: CGRect = CGRectZero
    var end: CGRect = CGRectZero
}

public class UPManager: NSObject, UITextViewDelegate {
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Constants
    //------------------------------------------------------------------------------------------------------------------
    
    private let defaultTopScrollingOffset: CGFloat = CGFloat(30)
    private let defaultBottomScrollingOffset: CGFloat = CGFloat(40)
    private let textViewSelection = UPTextViewSelection()
    private let UPContainerInset = UIEdgeInsetsMake(13, 2, 8, 2)
    private let UPContentInset = UIEdgeInsetsMake(2, 0, 2, 0)
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Variables
    //------------------------------------------------------------------------------------------------------------------
    
    // MARK: Public
    
    var defaultHeightConstant:CGFloat = 30
    var delegate: UITextViewDelegate?
    
    // MARK: Private
    
    /**
    * Represents how many points before reaching the bottom edge of the tableView, will scrolling occur (if applies)
    */
    private var bottomScrollingOffset:CGFloat = CGFloat(-1)
    
    /**
     * A dictionary of fake UITableViewCell instances, note that this dictionary will contain a key for every reuse
     * identifier passed as a parameter, with a cell instance for that identifier as the mapped object.
     * Each cell shall be reused behind the scenes to calculate the height required for the real cell.
     */
    private var offScreenCells: NSMutableDictionary!
    
    /**
     * A weak reference to a tableView instance, which shall contain all cells and textViews wherein this component will
     * work with
     */
    private weak var tableView: UITableView!
    
    /**
     * Stores the metadata related to every text view present in the table inside a NSMutableDictionary
     */
    private var managedTextViewsMetaData = NSMutableDictionary()
    
    /**
     * Stores all text views that need to be updated (i.e. its height must change) inside a
     * NSMutableDictionary => [key: text view reuse identifier, value: [key: index path, value: upId]]
     */
    private var managedTextViewsMapper = NSMutableDictionary()
    
    /**
     * Stores all Fake text views that will be used specifically for the height calculation methods, inside a dictionary
     * using the same behavior as for the managedTextViewsMapper
     */
    private var fakeTextViewsMapper = NSMutableDictionary()
    
    /**
     * Represents how many points before reaching the top edge of the tableView, will scrolling occur (if applies)
     */
    private var topScrollingOffset:CGFloat = CGFloat(-1)
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Lifecycle
    //------------------------------------------------------------------------------------------------------------------
    
    public init(delegate:UITextViewDelegate?, tableView: UITableView) {
        super.init()
        if let initializedTableView = tableView as UITableView? {
            self.tableView = initializedTableView
        }
        else {
            fatalError("UPManager initialized without a valid tableView instance")
        }
        if let textViewDelegate = delegate as UITextViewDelegate? {
            self.delegate = textViewDelegate
        }
        self.offScreenCells = NSMutableDictionary()
        
        topScrollingOffset = defaultTopScrollingOffset
        bottomScrollingOffset = defaultBottomScrollingOffset
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Public
    //------------------------------------------------------------------------------------------------------------------
    
    /**
    * Core method that returns the height required by a cell that may contain an instance of UITextView embedded within.
    * A chain of operations for calculating the height begin here, given some initial conditions:
    * @param indexPath The index path for the current UITableViewCell instance
    * @param cellReuseIdentifier The reuse identifier for the current cell instance
    * @param textForTextView A closure object that will return a string based on a specific textView for the index path
    * @param initialMetaDataForTextView A closure object that will return an instance of UPManagedTextViewMetaData which
    *        represents all meta data that may be required for further behaviors
    * @discussion If this method returns a value of 0 (zero) for the height, this might mean the there is a problem with
    *        the cell's reuse identifier, or auto layout for this cell. Of course, ignore if you do expect a 0.
    * @return The expected height for the cell at a specific index path, taking in consideration aspects such as
    *         the text to be displayed in the textView(s), the state of the textView(s) such as expanded or contracted,
    *         amongst other possible heuristics.
    */
    public func heightForRowAtIndexPath(indexPath: NSIndexPath,
        cellReuseIdentifier: String,
        textForTextView: (textView: UITextView) -> String,
        initialMetaDataForTextView: (textView: UITextView) -> UPManagedTextViewMetaData) -> CGFloat {
            
            var superViewBounds = CGRectZero
            if let superview = self.tableView.superview {
                superViewBounds = superview.bounds;
            }
            
            var currentCellInstance: UITableViewCell?
            
            if let mappedCell = offScreenCells[cellReuseIdentifier] as? UITableViewCell {
                currentCellInstance = mappedCell
            } else {
                currentCellInstance = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier)
            }
            
            if currentCellInstance != nil{
                return self.calculateHeightForConfiguredSizingCell(currentCellInstance!, tableView: self.tableView,
                    indexPath: indexPath, superViewBounds:superViewBounds, textForTextView: textForTextView,
                    initialMetaDataForTextView: initialMetaDataForTextView)
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
        
        let rectY:CGFloat = self.yCoordinateForEnclosingRectWithStartRect(selectionStartRect,
            endRect: selectionEndRect, visibleHeight: visibleHeight)
        
        if rectY >= 0 && !(selectionStartRect.origin.y == self.textViewSelection.start.origin.y &&
            selectionEndRect.origin.y == self.textViewSelection.end.origin.y)
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
    
    // MARK: Manager Settings
    
    public func configureManagedTextView(textView: UITextView, initialMetaData metaData:UPManagedTextViewMetaData) {
        textView.delegate = self
        self.configureInsetsForTextView(textView)
        self.addManagedUPTextView(textView, metaData: metaData)
    }
    
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
    
    public func startListeningForKeyboardEvents(){
        self.stopListeningForKeyboardEvents()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func stopListeningForKeyboardEvents(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Private
    //------------------------------------------------------------------------------------------------------------------
    
    // MARK: Auxiliary Height Calculating Methods
    
    // Note: we use systemLayoutFittingSize as the technique for retrieving cell height
    // in order to offer compatibility with iOS 7. Once we discard iOS 7 we might use the
    // advantages of iOS 8
    private func calculateHeightForConfiguredSizingCell(sizingCell: UITableViewCell,
        tableView: UITableView,
        indexPath: NSIndexPath,
        superViewBounds: CGRect,
        textForTextView: (textView: UITextView) -> String,
        initialMetaDataForTextView: (textView: UITextView) -> UPManagedTextViewMetaData) -> CGFloat {
            
            let textViews = textViewsForCell(sizingCell, indexPath: indexPath,
                initialMetaDataForTextView: initialMetaDataForTextView)
            
            for textView in textViews {
                
                if let currentTextView = textView as? UITextView {
                    
                    self.configureTextView(currentTextView, atIndexPath: indexPath,
                        textForTextView:textForTextView, initialMetaDataForTextView: initialMetaDataForTextView)
                }
            }
            
            let size: CGSize = sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            sizingCell.bounds = CGRectMake(sizingCell.bounds.origin.x, sizingCell.bounds.origin.y,
                CGRectGetWidth(superViewBounds), size.height)
            sizingCell.contentView.bounds = sizingCell.bounds
            
            sizingCell.setNeedsLayout()
            sizingCell.layoutIfNeeded()
            
            return size.height //+ absolutePaddingHeight
    }
    
    private func textViewsForCell(cell: UITableViewCell, indexPath: NSIndexPath,
        initialMetaDataForTextView: (textView: UITextView) -> UPManagedTextViewMetaData) -> NSArray {
            
            let textViews = NSMutableArray()
            
            findTextViewsOfView(cell.contentView, indexPath: indexPath, textViews: textViews,
                initialMetaDataForTextView: initialMetaDataForTextView)
            
            return textViews
    }
    
    // Do not allow UPEmbeddedTextViews to contain other UPEmbeddedTextViews
    private func findTextViewsOfView(view: UIView, indexPath: NSIndexPath, textViews:NSMutableArray,
        initialMetaDataForTextView: (textView: UITextView) -> UPManagedTextViewMetaData) {
            
            if let currentTextView = view as? UITextView {
                let initialMetadata = initialMetaDataForTextView(textView: currentTextView)
                
                self.addFakeManagedUPTextView(currentTextView, metaData: initialMetadata,
                    reuseIdentifier: initialMetadata.reusableIdentifier)
                
                self.addFakeBaseManagedTextViewMapperIfNeededForTextView(currentTextView,
                    reusableIdentifier: initialMetadata.reusableIdentifier)
                textViews.addObject(currentTextView)
                
            } else {
                
                for currentView in view.subviews {
                    findTextViewsOfView(currentView , indexPath: indexPath, textViews: textViews,
                        initialMetaDataForTextView: initialMetaDataForTextView)
                }
            }
    }
    
    private func configureTextView(textView: UITextView, atIndexPath indexPath: NSIndexPath,
        textForTextView: (textView:UITextView) -> String,
        initialMetaDataForTextView: (textView: UITextView) -> UPManagedTextViewMetaData) {
            
            let textViewMetaData = initialMetaDataForTextView(textView: textView)
            textView.text = textForTextView(textView:textView)
            
            if let metaData = self.fakeMetaDataForReuseIdentifier(textViewMetaData.reusableIdentifier) as
                UPManagedTextViewMetaData? {
                    
                    let textViewSize = self.sizeForTextView(textView, atIndexPath: indexPath,
                        reuseIdentifier: metaData.reusableIdentifier).height + self.getAbsolutePaddingHeight()
                    
                    textView.addConstraint(NSLayoutConstraint(item: textView,
                        attribute: NSLayoutAttribute.Height,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: nil,
                        attribute: NSLayoutAttribute.NotAnAttribute,
                        multiplier: 1,
                        constant: textViewSize))
            }
    }
    
    private func getCurrentWidthForTextView(textView: UITextView, atIndexPath indexPath: NSIndexPath,
        reuseIdentifier: String) -> CGFloat {
            
            var textViewWidth = CGRectGetWidth(self.tableView.bounds)
            if let textViewMetaData = self.metaDataForReuseIdentifier(reuseIdentifier, indexPath: indexPath) as
                UPManagedTextViewMetaData? {
                    
                    if let currentWidth = textViewMetaData.currentWidth {
                        textViewWidth = currentWidth
                    }
            }
            
            return textViewWidth
    }
    
    private func sizeForTextView(textView: UITextView, atIndexPath indexPath: NSIndexPath,
        reuseIdentifier: String) -> CGSize {
            
            let textViewWidth = getCurrentWidthForTextView(textView, atIndexPath: indexPath,
                reuseIdentifier: reuseIdentifier)
            var textViewSize = textView.sizeThatFits(CGSizeMake(textViewWidth, CGFloat.max))
            
            if let fakeMetaData = self.fakeMetaDataForReuseIdentifier(reuseIdentifier) as UPManagedTextViewMetaData?
            {
                if let metaData = self.metaDataForReuseIdentifier(fakeMetaData.reusableIdentifier, indexPath: indexPath)
                    as UPManagedTextViewMetaData?{
                        if metaData.enableAutomaticCollapse &&
                            metaData.shouldCollapseHeightIfNeeded &&
                            textViewSize.height > metaData.collapsedHeightConstant{
                                textViewSize.height = metaData.collapsedHeightConstant
                                self.removeChangingTextViewMapForReuseIdentifier(metaData.reusableIdentifier,
                                    atIndexPath: indexPath)
                        }
                }
                else if fakeMetaData.enableAutomaticCollapse &&
                    textViewSize.height > fakeMetaData.collapsedHeightConstant {
                        textViewSize.height = fakeMetaData.collapsedHeightConstant
                }
            }
            
            return textViewSize
    }
    
    // MARK: Auxiliary Zoom Methods
    
    private func yCoordinateForEnclosingRectWithStartRect(startRect:CGRect, endRect:CGRect,
        visibleHeight:CGFloat) -> CGFloat
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
            if (endRect.origin.y > self.textViewSelection.end.origin.y &&
                endRect.origin.y > contentOffsetY2 - bottomScrollingOffset)
            {
                rectY = contentOffsetY2 - visibleHeight + 15
                rectY = rectY < 0 ? 0 : rectY
            }
                // Current end selection is scrolling towards the top
            else if endRect.origin.y < self.textViewSelection.end.origin.y &&
                endRect.origin.y < contentOffsetY + topScrollingOffset
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
                // Current start selection is scrolling towards the top
            else if (startRect.origin.y < self.textViewSelection.start.origin.y &&
                startRect.origin.y < contentOffsetY + topScrollingOffset)
            {
                rectY = contentOffsetY - 15
                rectY = rectY < 0 ? 0 : rectY
            }
                // Current start selection is scrolling towards the bottom
            else if (startRect.origin.y > self.textViewSelection.start.origin.y &&
                startRect.origin.y > contentOffsetY2 - bottomScrollingOffset)
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
        return CGRectEqualToRect(self.textViewSelection.start, CGRectZero) ||
            CGRectEqualToRect(self.textViewSelection.end, CGRectZero)
    }
    
    // MARK: Private Utilities
    
    private func textView(textView: UITextView, shouldCollapseIfNeeded shouldCollapse:Bool) {
        if let upTextView = textView as UITextView? {
            if let metaData = self.metaDataForManagedTextView(upTextView) as UPManagedTextViewMetaData? {
                if metaData.enableAutomaticCollapse {
                    let center = upTextView.center
                    let rootViewPoint = upTextView.superview!.convertPoint(center, toView:self.tableView)
                    if let indexPath = self.tableView.indexPathForRowAtPoint(rootViewPoint) as NSIndexPath? {
                        self.enqueueChangingTextView(upTextView, atIndexPath: indexPath)
                    }
                    metaData.shouldCollapseHeightIfNeeded = shouldCollapse
                }
            }
        }
    }
    
    private func previousSizeDictionaryRepresentation(textView: UITextView) -> CFDictionary {
        if let metaData = self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData? {
            if let managedTextViewPreviousRect = metaData.previousRectDictionaryRepresentation as NSDictionary? {
                return managedTextViewPreviousRect
            }
        }
        return [:]
    }
    
    private func previousSizeForUPTextView(textView: UITextView) -> CGSize {
        var previousSize = CGSizeZero
        CGSizeMakeWithDictionaryRepresentation(self.previousSizeDictionaryRepresentation(textView), &previousSize)
        return previousSize
    }
    
    private func configureWidthForTextView(textView: UITextView) {
        
        let fixedWidth = textView.frame.width
        if let metaData = self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData? {
            
            if metaData.currentWidth != fixedWidth {
                metaData.currentWidth = fixedWidth
            }
            
        }
    }
    
    private func configureInsetsForTextView(textView: UITextView) {
        textView.textContainerInset =
            UIEdgeInsetsMake(UPContainerInset.top,
                UPContainerInset.left,
                UPContainerInset.bottom,
                UPContainerInset.right)
        
        textView.contentInset =
            UIEdgeInsetsMake(UPContentInset.top,
                UPContentInset.left,
                UPContentInset.bottom,
                UPContentInset.right)
    }
    
    private func getAbsolutePaddingHeight() -> CGFloat {
        
        return abs(UPContainerInset.top) + abs(UPContainerInset.bottom) +
            abs(UPContentInset.top) + abs(UPContentInset.bottom)
    }
    
    // MARK: Managed UPEmbeddedTextView and Meta Data auxiliary methods
    
    private func addFakeManagedUPTextView(textView: UITextView, metaData: UPManagedTextViewMetaData,
        reuseIdentifier: String) {
            if !self.isFakeManagedUPTextViewWithReuseIdentifier(reuseIdentifier) {
                textView.translatesAutoresizingMaskIntoConstraints = false
                self.fakeTextViewsMapper[reuseIdentifier] = metaData
            }
    }
    
    private func addManagedUPTextView(textView: UITextView, metaData: UPManagedTextViewMetaData) {
        if !self.isManagedUPTextView(textView){
            textView.tag = self.managedTextViewsMetaData.count + 1
            self.managedTextViewsMetaData[textView.tag] = metaData
            let previousSize = CGSizeZero
            self.setManagedUPTextView(textView, previousSize: previousSize)
        }
    }
    
    private func addBaseManagedTextViewMapperIfNeededForTextView(textView: UITextView) {
        if let metaData = self.metaDataAtIndex(textView.tag) as UPManagedTextViewMetaData? {
            if self.managedTextViewsMapper[metaData.reusableIdentifier] == nil {
                // Gotta add this reuse identifier
                self.managedTextViewsMapper[metaData.reusableIdentifier] = NSMutableDictionary()
            }
        }
    }
    
    private func addFakeBaseManagedTextViewMapperIfNeededForTextView(textView: UITextView, reusableIdentifier: String) {
        if let fakeMetadata = self.fakeMetaDataForReuseIdentifier(reusableIdentifier) as UPManagedTextViewMetaData? {
            if self.managedTextViewsMapper[fakeMetadata.reusableIdentifier] == nil {
                // Gotta add this reuse identifier
                self.managedTextViewsMapper[fakeMetadata.reusableIdentifier] = NSMutableDictionary()
            }
        }
    }
    
    private func setManagedUPTextView(textView: UITextView, previousSize:CGSize) {
        if let metaData = self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData? {
            metaData.previousRectDictionaryRepresentation = CGSizeCreateDictionaryRepresentation(previousSize)
        }
    }
    
    private func isFakeManagedUPTextViewWithReuseIdentifier(reuseIdentifier: String) -> Bool {
        if ((self.fakeMetaDataForReuseIdentifier(reuseIdentifier) as UPManagedTextViewMetaData?) != nil) {
            return true
        }
        return false
    }
    
    private func isManagedUPTextView(textView: UITextView) -> Bool {
        if ((self.metaDataForManagedTextView(textView) as UPManagedTextViewMetaData?) != nil) {
            return true
        }
        return false
    }
    
    private func metaDataForManagedTextView(textView: UITextView) -> UPManagedTextViewMetaData? {
        return self.metaDataAtIndex(textView.tag)
    }
    
    private func metaDataForReuseIdentifier(reuseId: String, indexPath: NSIndexPath) -> UPManagedTextViewMetaData? {
        if let indexPaths = self.managedTextViewsMapper[reuseId] as? NSMutableDictionary {
            if let upId = indexPaths[NSIndexPath(forRow: indexPath.row, inSection: indexPath.section)] as? NSInteger {
                return self.metaDataAtIndex(upId)
            }
        }
        return nil
    }
    
    private func fakeMetaDataForReuseIdentifier(reuseId: String) -> UPManagedTextViewMetaData? {
        if let metaData = self.fakeTextViewsMapper[reuseId] as? UPManagedTextViewMetaData {
            return metaData
        }
        return nil
    }
    
    private func metaDataAtIndex(index: Int) -> UPManagedTextViewMetaData? {
        return self.managedTextViewsMetaData[index] as? UPManagedTextViewMetaData
    }
    
    private func enqueueChangingTextView(textView: UITextView!, atIndexPath indexPath: NSIndexPath!) {
        if let metaData = self.metaDataAtIndex(textView.tag) as UPManagedTextViewMetaData? {
            if let indexPaths = self.managedTextViewsMapper[metaData.reusableIdentifier] as? NSMutableDictionary {
                indexPaths.setObject(textView.tag, forKey: NSIndexPath(forRow: indexPath.row,
                    inSection: indexPath.section))
            }
        }
        
    }
    
    private func removeChangingTextViewMapForReuseIdentifier(reuseId: String, atIndexPath indexPath:NSIndexPath){
        if let indexPaths = self.managedTextViewsMapper[reuseId] as? NSMutableDictionary{
            indexPaths.removeObjectForKey(NSIndexPath(forRow: indexPath.row, inSection: indexPath.section))
        }
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - UITextViewDelegate
    //------------------------------------------------------------------------------------------------------------------
    
    public func textViewDidChange(textView: UITextView) {
        if let delegate = self.delegate as UITextViewDelegate? {
            if delegate.respondsToSelector("textViewDidChange:") {
                delegate.textViewDidChange!(textView)
            }
        }
        if let upTextView = textView as UITextView? {
            if self.isManagedUPTextView(upTextView) {
                
                let fixedWidth = upTextView.frame.width
                let currentSize: CGSize = upTextView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max));
                let previousSize = self.previousSizeForUPTextView(upTextView)
                
                if (!CGSizeEqualToSize(currentSize, previousSize)) {
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
    
    public func textViewDidChangeSelection(textView: UITextView) {
        self.updateTextViewZoomArea(textView)
        if let delegate = self.delegate as UITextViewDelegate? {
            if delegate.respondsToSelector("textViewDidChangeSelection:") {
                delegate.textViewDidChangeSelection!(textView)
            }
        }
    }
    
    public func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        var shouldBeginEditing = true
        if let delegate = self.delegate as UITextViewDelegate?{
            if delegate.respondsToSelector("textViewShouldBeginEditing:") {
                shouldBeginEditing = delegate.textViewShouldBeginEditing!(textView)
            }
        }
        self.textView(textView, shouldCollapseIfNeeded: false)
        if shouldBeginEditing {
            
            if let upTextView = textView as UITextView? {
                configureWidthForTextView(upTextView)
            }
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.textViewSelection.start = CGRectZero
            self.textViewSelection.end = CGRectZero
            
        }
        
        return shouldBeginEditing
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        self.textView(textView, shouldCollapseIfNeeded: true)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        if let delegate = self.delegate as UITextViewDelegate? {
            if delegate.respondsToSelector("textViewDidEndEditing:") {
                delegate.textViewDidEndEditing!(textView)
            }
        }
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Forward Invocation
    //------------------------------------------------------------------------------------------------------------------
    
    override public func respondsToSelector(aSelector: Selector) -> Bool {
        return super.respondsToSelector(aSelector) || self.delegate?.respondsToSelector(aSelector) == true
    }
    
    override public func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        if self.delegate?.respondsToSelector(aSelector)==true{
            return self.delegate
        }
        return super.forwardingTargetForSelector(aSelector)
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Keyboard Observer
    //------------------------------------------------------------------------------------------------------------------
    
    func keyboardWillShow(notification: NSNotification)
    {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            
            var contentInsets = self.tableView.contentInset
            contentInsets = UIEdgeInsets(top: contentInsets.top, left: contentInsets.left,
                bottom: keyboardSize.height + UIApplication.sharedApplication().statusBarFrame.size.height,
                right: contentInsets.right)
            
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
        contentInsets = UIEdgeInsets(top: contentInsets.top, left: contentInsets.left,
            bottom: 0, right: contentInsets.right)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Deinit
    //------------------------------------------------------------------------------------------------------------------
    
    deinit{
        self.stopListeningForKeyboardEvents()
    }
}