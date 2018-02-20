//
//  Toolbar.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/20/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class Toolbar {
    
    class func getDoneToolbar(done: UIBarButtonItem) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.barStyle = .default
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbar.items = [flex, done]
        return toolbar
    }
    
}
