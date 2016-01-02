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
public class UPManagedTextViewMetaData: NSObject {
    
    /**
     * Contains a dictionary representation of a CGRect which contains an imaginary rect that would be of the enough
     * size to contain all of the text within the UITextView. Such rect is required in order to know if the text view
     * increases or decrases in content (vertically speaking), making the cell adjust the size to the new content's.
     */
    var previousRectDictionaryRepresentation: NSDictionary?
    
    /**
     * A height constraint instance that shall be added to a UITextView instance on order for the systemLayoutFittingSize
     * to work correctly and hence return the appropriate value for the height of a cell.
     */
    var textViewHeightConstraint:NSLayoutConstraint!
    
    /**
     * A flag that will tell the UPManager if a text view should be collapsed
     */
    var shouldCollapseHeightIfNeeded: Bool = true
    
    /**
     * Stores the reusable identifier given for a specific text view.
     */
    var reusableIdentifier: String!
    
    /**
     * Contains a value for the width that a text view may be occupying at a specific time. This property is solely
     * managed by the UPManager
     */
    var currentWidth: CGFloat?
    
    /**
     * A flag that can be set by the client to allow or disallow text views from collapsing or expanding automatically
     */
    var enableAutomaticCollapse: Bool = true
    
    /**
     * Clients may play with this variable in order to change the default height of a collapsed text view
     */
    var collapsedHeightConstant: CGFloat = 125
    
    /**
     * Constructs a new instance of this class.
     * @param reuseIdentifier A non nil String which correctly identifies a UITextView instance embedded in a UITableViewCell
     * @param enableAutomaticCollapse Flag indicating if the UPManager may automatically expand or collapse the text view
     * @param collapsedHeightConstant A constant for specifying the height for the text view, should this be collapsed
     *
     * @return An instance of this class should all parameters were valid. Possibly a crash if the reuse identifier is nil
     */
    public required init(reuseIdentifier: String!, enableAutomaticCollapse: Bool, collapsedHeightConstant: CGFloat) {
        self.reusableIdentifier = reuseIdentifier
        self.enableAutomaticCollapse = enableAutomaticCollapse
        self.collapsedHeightConstant = collapsedHeightConstant
    }
}