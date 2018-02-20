//
//  MainTabBarController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

class MainTabBarController: UITabBarController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil && FBSDKAccessToken.current() == nil {
            let loginNC = storyboard?.instantiateViewController(withIdentifier: "LoginNavigationController") as! UINavigationController
            self.present(loginNC, animated: false, completion: nil)
        } else if let user = Auth.auth().currentUser {
            FirebaseClient.shared.setUserData(user: user)
        }
    }
    
}

enum Tabs: Int {
    case lessons = 0
    case messages = 1
    case events = 2
    case prayerRequests = 3
    case account = 4
}
