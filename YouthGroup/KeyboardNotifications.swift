//
//  KeyboardNotifications.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class KeyboardNotifications {

    class func subscribe(vc: UIViewController, showSelector: Selector, hideSelector: Selector) {
        NotificationCenter.default.addObserver(vc, selector: showSelector, name: NSNotification.Name.UIKeyboardWillShow,object: nil)
        NotificationCenter.default.addObserver(vc, selector: hideSelector, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    class func unsubscribe(vc: UIViewController) {
        NotificationCenter.default.removeObserver(vc, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(vc, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    class func getKeyboardHeight(notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }

}
