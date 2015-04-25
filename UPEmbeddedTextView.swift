//
//  UPEmbeddedTextView.swift
//  UPEmbeddedTextView
//
//  Created by Martin Uribe on 4/5/15.
//  Copyright (c) 2015 up. All rights reserved.
//

import UIKit

class UPEmbeddedTextView: UITextView {
    
    let UPContainerInset = UIEdgeInsetsMake(18, 4, -4, 0)
    let UPContentInset = UIEdgeInsetsMake(4, 0, 0, 0)
    
    var previousRect: CGRect! = CGRectZero
    var textViewWidthConstraint: NSLayoutConstraint?
    var textViewHeightConstraint:NSLayoutConstraint!
    var defaultHeightConstant:CGFloat = 30
    var collapsedHeigthConstant: CGFloat = 10
    var enableAutomaticCollapse: Bool = true
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
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
            self.addConstraint(self.textViewHeightConstraint)
        }
        
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    func configureInsets() {
        
    }
    
    func getAbsolutePaddingHeight() -> CGFloat {
        
        return UPContainerInset.top + UPContainerInset.bottom + UPContentInset.top + UPContentInset.bottom
    }

}
