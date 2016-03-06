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

public class UPTextViewManagerDefaults: UPTextViewMetadataProtocol {
    
    /**
     * A flag that can be set by the client to allow or disallow text views from collapsing or expanding automatically
     */
    var enableAutomaticCollapse: Bool = true
    
    /**
    * Clients may play with this variable in order to change the default height of a collapsed text view
    */
    var collapsedHeightConstant: CGFloat = 125
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
     * A weak reference to a tableView instance, which shall contain all cells and textViews wherein this component will
     * work with
     */
    private weak var tableView: UITableView!
    
    /**
     * Stores the metadata related to every text view present in the table inside a NSMutableDictionary
     */
    private var managedTextViewsMetaData = NSMutableDictionary()
    
    /**
     * Keeps a record of the default settings that will be needed for orphan text views
     */
    private var defaults: UPTextViewManagerDefaults!
    
    /**
     * Represents how many points before reaching the top edge of the tableView, will scrolling occur (if applies)
     */
    private var topScrollingOffset:CGFloat = CGFloat(-1)
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Lifecycle
    //------------------------------------------------------------------------------------------------------------------
    
    public init(delegate:UITextViewDelegate?, tableView: UITableView, defaults: UPTextViewManagerDefaults?) {
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
        self.defaults = defaults ?? UPTextViewManagerDefaults()
        topScrollingOffset = defaultTopScrollingOffset
        bottomScrollingOffset = defaultBottomScrollingOffset
    }
    
    //------------------------------------------------------------------------------------------------------------------
    // MARK: - Public
    //------------------------------------------------------------------------------------------------------------------
    
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
    
    public func registerMetadata(metadata: UPManagedTextViewMetadata!, indexPath: NSIndexPath!) {
        guard let textView = metadata.textView as UITextView? else {
            return
        }
        textView.delegate = self
        self.configureInsetsForTextView(textView) // TODO: Is this necessary>???
        self.addManagedUPTextViewMetadata(metadata, indexPath: indexPath)
    }
    
    func autodiscoverCell(cell: UITableViewCell) {
        // TODO:
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
    
    private func updateTextView(textView: UITextView, atIndexPath indexPath: NSIndexPath) {
        guard let textViewMetaData = metadataForTextView(textView) as UPManagedTextViewMetadata? else {
            return
        }
        let textViewSize = self.sizeForTextView(textView, atIndexPath: indexPath).height + self.getAbsolutePaddingHeight()
        textViewMetaData.textViewHeightConstraint.constant = textViewSize
        textView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func getCurrentWidthForTextView(textView: UITextView, atIndexPath indexPath: NSIndexPath) -> CGFloat {
            
            var textViewWidth = CGRectGetWidth(self.tableView.bounds)
            if let textViewMetadata = self.metadataForTextView(textView, indexPath: indexPath) as
                UPManagedTextViewMetadata? {
                    
                    if let currentWidth = textViewMetadata.currentWidth {
                        textViewWidth = currentWidth
                    }
            }
            
            return textViewWidth
    }
    
    private func sizeForTextView(textView: UITextView, atIndexPath indexPath: NSIndexPath) -> CGSize {
            
            let textViewWidth = getCurrentWidthForTextView(textView, atIndexPath: indexPath)
            var textViewSize = textView.sizeThatFits(CGSizeMake(textViewWidth, CGFloat.max))
            
        if let metadata = self.metadataForTextView(textView, indexPath: indexPath)
            as UPManagedTextViewMetadata?{
                if metadata.enableAutomaticCollapse &&
                    metadata.shouldCollapseHeightIfNeeded &&
                    textViewSize.height > metadata.collapsedHeightConstant{
                        textViewSize.height = metadata.collapsedHeightConstant
                }
        }
        else if defaults.enableAutomaticCollapse &&
            textViewSize.height > defaults.collapsedHeightConstant {
                textViewSize.height = defaults.collapsedHeightConstant
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
    
    private func indexPathOfTextView(textView: UITextView!) -> NSIndexPath? {
        let center = textView.center
        let rootViewPoint = textView.superview!.convertPoint(center, toView:self.tableView)
        return self.tableView.indexPathForRowAtPoint(rootViewPoint)
    }
    
    private func metadataForTextView(textView: UITextView) -> UPManagedTextViewMetadata? {
        guard let indexPath = self.indexPathOfTextView(textView) as NSIndexPath? else {
            return nil
        }
        return self.metadataForTextView(textView, indexPath: indexPath)
    }
    
    private func textView(textView: UITextView!, shouldCollapseIfNeeded shouldCollapse:Bool) {
        guard let indexPath = self.indexPathOfTextView(textView) as NSIndexPath? else {
            return
        }
        if let metaData = self.metadataForTextView(textView, indexPath: indexPath) as UPManagedTextViewMetadata? {
            if metaData.enableAutomaticCollapse {
                metaData.shouldCollapseHeightIfNeeded = shouldCollapse
            }
        }
    }
    
    private func previousSizeDictionaryRepresentation(textView: UITextView) -> CFDictionary {
        if let metaData = self.metadataForTextView(textView) as UPManagedTextViewMetadata? {
            if let managedTextViewPreviousRect = metaData.previousRectDictionaryRepresentation as NSDictionary? {
                return managedTextViewPreviousRect
            }
        }
        return [:]
    }
    
    private func previousSizeForTextView(textView: UITextView) -> CGSize {
        var previousSize = CGSizeZero
        CGSizeMakeWithDictionaryRepresentation(self.previousSizeDictionaryRepresentation(textView), &previousSize)
        return previousSize
    }
    
    private func configureWidthForTextView(textView: UITextView) {
        
        let fixedWidth = textView.frame.width
        if let metaData = self.metadataForTextView(textView) as UPManagedTextViewMetadata? {
            
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
    
    private func addManagedUPTextViewMetadata(metadata: UPManagedTextViewMetadata!, indexPath: NSIndexPath!) {
        guard let metadataArray = self.managedTextViewsMetaData[indexPath] as? [UPManagedTextViewMetadata] else {
            managedTextViewsMetaData[indexPath] = [UPManagedTextViewMetadata]()
            addManagedUPTextViewMetadata(metadata, indexPath: indexPath)
            return
        }
        let filteredArray = arrayWithoutDuplicatesForMetadata(metadata, inArray: metadataArray)
        managedTextViewsMetaData[indexPath] = filteredArray
        metadata.previousRectDictionaryRepresentation = CGSizeCreateDictionaryRepresentation(CGSizeZero)
    }
    
    private func arrayWithoutDuplicatesForMetadata(metadata: UPManagedTextViewMetadata, inArray array: [UPManagedTextViewMetadata]) -> [UPManagedTextViewMetadata] {
        var filteredArray = [UPManagedTextViewMetadata]()
        for includedMetadata in array {
            if metadata.textView != includedMetadata.textView {
                filteredArray.append(includedMetadata)
            }
        }
        filteredArray.append(metadata)
        
        return filteredArray
    }
    
    private func metadataTupleForTextView(textView: UITextView, indexPath: NSIndexPath) -> (index: Int, metadata: UPManagedTextViewMetadata)? {
        guard let metadataArray = self.managedTextViewsMetaData[indexPath] as? [UPManagedTextViewMetadata] else {
            return nil
        }
        var metadata: (Int, UPManagedTextViewMetadata)?
        for (index, includedMetadata) in metadataArray.enumerate() {
            if textView == includedMetadata.textView {
                metadata = (index, includedMetadata)
                break
            }
        }
        return metadata
    }
    
    private func metadataForTextView(textView: UITextView, indexPath: NSIndexPath) -> UPManagedTextViewMetadata? {
        return self.metadataTupleForTextView(textView, indexPath: indexPath)?.metadata
    }

    private func setTextViewPreviousSize(previousSize:CGSize, textView: UITextView, indexPath: NSIndexPath) {
        if let metadata = self.metadataForTextView(textView, indexPath: indexPath) as UPManagedTextViewMetadata? {
            metadata.previousRectDictionaryRepresentation = CGSizeCreateDictionaryRepresentation(previousSize)
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
        updateTextViewSizeIfNeeded(textView)
    }
    
    private func updateTextViewSizeIfNeeded(textView: UITextView!) {
        guard let textViewIndexPath = indexPathOfTextView(textView) as NSIndexPath? else {
            return // ERROR! There must always be an index path, as a precondition
        }
        guard let _ = metadataForTextView(textView) as UPManagedTextViewMetadata? else {
            let defaultMetadata = UPManagedTextViewMetadata(textView: textView, heightConstraint: nil,
                enableAutomaticCollapse: defaults.enableAutomaticCollapse,
                collapsedHeightConstant: defaults.collapsedHeightConstant)
            registerMetadata(defaultMetadata, indexPath: textViewIndexPath)
            updateTextViewSizeIfNeeded(textView)
            return
        }
        let fixedWidth = CGRectGetWidth(textView.frame)
        let currentSize: CGSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max));
        let previousSize = self.previousSizeForTextView(textView)
        updateTextView(textView, atIndexPath: textViewIndexPath)
        
        if (!CGSizeEqualToSize(currentSize, previousSize)) {
            setTextViewPreviousSize(currentSize, textView: textView, indexPath: textViewIndexPath)
            if !CGSizeEqualToSize(currentSize, CGSizeZero)
            {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
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
                if let textViewIndexPath = indexPathOfTextView(textView) as NSIndexPath? {
                    updateTextView(textView, atIndexPath: textViewIndexPath)
                }
            }
            
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            self.textViewSelection.start = CGRectZero
            self.textViewSelection.end = CGRectZero
            
        }
        
        return shouldBeginEditing
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        guard let textViewIndexPath = indexPathOfTextView(textView) as NSIndexPath? else {
            return // ERROR! There must always be an index path, as a precondition
        }
        self.textView(textView, shouldCollapseIfNeeded: true)
        updateTextView(textView, atIndexPath: textViewIndexPath)
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