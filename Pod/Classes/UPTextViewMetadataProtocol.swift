//
//  UPTextViewMetadataProtocol.swift
//  Pods
//
//  Created by Uribe, Martin on 2/28/16.
//
//

import Foundation

protocol UPTextViewMetadataProtocol {
    
    /**
     * A flag that can be set by the client to allow or disallow text views from collapsing or expanding automatically
     */
    var enableAutomaticCollapse: Bool { get set }// = true
    
    /**
     * Clients may play with this variable in order to change the default height of a collapsed text view
     */
    var collapsedHeightConstant: CGFloat { get set }// = 125
}
