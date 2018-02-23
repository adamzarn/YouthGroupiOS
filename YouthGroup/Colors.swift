//
//  Colors.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/13/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit



struct Colors {
    static let darkGray = UIColor(rgb: 0x5D5C61)
    static let lightGray = UIColor(rgb: 0x379683)
    static let lightBlue = UIColor(rgb: 0x7395AE)
    static let darkBlue = UIColor(rgb: 0x557A95)
    static let beige = UIColor(rgb: 0xB1A296)
}

func makeColor(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
    return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
