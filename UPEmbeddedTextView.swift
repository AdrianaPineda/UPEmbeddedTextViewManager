//
//  UPEmbeddedTextView.swift
//  UPEmbeddedTextView
//
//  Created by Martin Uribe on 4/5/15.
//  Copyright (c) 2015 up. All rights reserved.
//

import UIKit

public class UPEmbeddedTextView: UITextView {
    
    let UPContainerInset = UIEdgeInsetsMake(13, 0, 8, 0)
    let UPContentInset = UIEdgeInsetsMake(2, 0, 2, 0)
    
    var textViewHeightConstraint:NSLayoutConstraint!
    var defaultHeightConstant:CGFloat = 30
    var collapsedHeightConstant: CGFloat = 125
    var enableAutomaticCollapse: Bool = true
    var upId: NSInteger = -1
    var reuseIdentifier: String! = "defaultUPTextView"
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.configureInsets()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureInsets()
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
    
    func configureInsets() {
        self.textContainerInset =
            UIEdgeInsetsMake(UPContainerInset.top,
                UPContainerInset.left,
                UPContainerInset.bottom,
                self.textContainerInset.right)
        
        self.contentInset =
            UIEdgeInsetsMake(UPContentInset.top,
                self.contentInset.left,
                UPContentInset.bottom,
                self.contentInset.right)
        
        if (self.textViewHeightConstraint == nil){
            self.setTranslatesAutoresizingMaskIntoConstraints(false)
            self.textViewHeightConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: self.defaultHeightConstant)
        }
    }
    
    func getAbsolutePaddingHeight() -> CGFloat {
        
        return abs(UPContainerInset.top) + abs(UPContainerInset.bottom) + abs(UPContentInset.top) + abs(UPContentInset.bottom)
    }
    
    public override var delegate:UITextViewDelegate?{
        didSet{
            if let upDelegate = self.delegate as? UPManager {
                upDelegate.addManagedUPTextView(self)
            }
        }
    }
}
