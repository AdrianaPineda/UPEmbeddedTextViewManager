//
//  UPManagedTextViewMetaData.swift
//  UPEmbeddedTextView
//
//  Created by Martin Uribe on 8/9/15.
//  Copyright (c) 2015 up. All rights reserved.
//

/**
* Manages data related to the Text View
* used when its height must change
*/
public class UPManagedTextViewMetadata: NSObject, UPTextViewMetadataProtocol {
    
    /**
     * Contains a dictionary representation of a CGRect which contains an imaginary rect that would be of the enough
     * size to contain all of the text within the UITextView. Such rect is required in order to know if the text view
     * increases or decrases in content (vertically speaking), making the cell adjust the size to the new content's.
     */
    var previousRectDictionaryRepresentation: NSDictionary?
    
    /**
     * A height constraint instance that shall be added to a UITextView instance in order for the systemLayoutFittingSize
     * to work correctly and hence return the appropriate value for the height of a cell.
     */
    lazy var textViewHeightConstraint: NSLayoutConstraint! = self.initialTextViewHeightConstraint()
    
    /**
     * A flag that can be set by the client to allow or disallow text views from collapsing or expanding automatically
     */
    var enableAutomaticCollapse: Bool = true
    
    /**
    * Clients may play with this variable in order to change the default height of a collapsed text view
    */
    var collapsedHeightConstant: CGFloat = 125
    
    /**
     * A flag that will tell the UPManager if a text view should be collapsed
     */
    var shouldCollapseHeightIfNeeded: Bool = true
    
    /**
     * Stores the reusable identifier given for a specific text view.
     */
    weak var textView: UITextView?
    
    /**
     * Contains a value for the width that a text view may be occupying at a specific time. This property is solely
     * managed by the UPManager
     */
    var currentWidth: CGFloat?
    
    /**
     * Constructs a new instance of this class.
     * @param textView A reference to the UITextView object for which custom characteristics are required
     * @param enableAutomaticCollapse Flag indicating if the UPManager may automatically expand or collapse the text view
     * @param collapsedHeightConstant A constant for specifying the height for the text view, should this be collapsed
     *
     * @return An instance of this class should all parameters were valid. Possibly a crash if the reuse identifier is nil
     */
    public required init(textView: UITextView!, heightConstraint: NSLayoutConstraint?, enableAutomaticCollapse: Bool, collapsedHeightConstant: CGFloat) {
        super.init()
        self.textView = textView
        self.enableAutomaticCollapse = enableAutomaticCollapse
        self.collapsedHeightConstant = collapsedHeightConstant
        if heightConstraint != nil {
            self.textViewHeightConstraint = heightConstraint!
        }
        NSLayoutConstraint.activateConstraints([textViewHeightConstraint])
    }
    
    private func initialTextViewHeightConstraint() -> NSLayoutConstraint? {
        guard let textView = self.textView as UITextView? else {
            return nil
        }
        let heightConstraint = NSLayoutConstraint(item: textView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1,
            constant: collapsedHeightConstant)
        heightConstraint.priority = 800
        return heightConstraint
    }
}