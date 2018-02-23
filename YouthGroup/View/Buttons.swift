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
    
    var color: UIColor = Colors.darkBlue
    
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
        layer.borderWidth = 1.0
        layer.borderColor = Colors.darkBlue.cgColor
        
    }
    
}

class CheckboxButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    init(){
        super.init(frame: CGRect.zero)
        setUp()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    func setUp(){
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }
    
}

