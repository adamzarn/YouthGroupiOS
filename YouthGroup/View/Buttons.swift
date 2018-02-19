//
//  Buttons.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/13/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class YouthGroupButton: UIButton {
    
    var color: UIColor = Colors.secondary
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = color
        tintColor = UIColor.white
        titleLabel?.textColor = UIColor.white
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5
        layer.cornerRadius = 5.0
        titleEdgeInsets.left = 5.0
        titleEdgeInsets.right = 5.0
        
    }
    
}

class CheckboxButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
    }
}

