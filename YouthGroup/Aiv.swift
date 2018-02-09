//
//  AIV.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class Aiv {
    
    class func show(aiv: UIActivityIndicatorView) {
        aiv.isHidden = false
        aiv.startAnimating()
    }
    
    class func hide(aiv: UIActivityIndicatorView) {
        aiv.isHidden = true
        aiv.stopAnimating()
    }
    
}
