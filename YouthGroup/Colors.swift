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
    static let primary = makeColor(r: 157,g: 27,b: 27)
    static let secondary = makeColor(r: 84,g: 80,b: 80)
    static let dark = makeColor(r: 74,g: 2,b: 2)
}

func makeColor(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
    return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
}
