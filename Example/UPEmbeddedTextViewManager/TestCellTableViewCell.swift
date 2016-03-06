//
//  TestCellTableViewCell.swift
//  UPEmbeddedTextView
//
//  Created by Martín Uribe on 4/18/15.
//  Copyright (c) 2015 up. All rights reserved.
//
//  Disclaimer:
//  TEST!! Ideally, this class represents a common UITableViewCell subclass
//  used by anyone who attempts to use the library. It is not and should not
//  however, be (a required) part of the library if possible.
//

import UIKit
import UPEmbeddedTextViewManager

class TestCellTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
