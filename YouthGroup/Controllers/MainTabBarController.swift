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
    
    override func viewWillAppear(_ animated: Bool) {
        self.selectedIndex = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil && FBSDKAccessToken.current() == nil {
            let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            self.present(loginVC, animated: false, completion: nil)
        } else if let user = Auth.auth().currentUser {
            FirebaseClient.shared.setUserData(user: user)
        }
    }
    
}
