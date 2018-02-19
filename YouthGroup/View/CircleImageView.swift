//
//  CircleImageView.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/17/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class CircleImageView: UIImageView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = frame.size.width/2
        layer.masksToBounds = true
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = frame.size.width/80.0
        contentMode = .scaleAspectFill
    }
    
}
