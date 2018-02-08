//
//  LoginViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/7/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let fbLoginButton = FBSDKLoginButton()
        fbLoginButton.readPermissions = ["public_profile", "email"]
        fbLoginButton.center = self.view.center
        self.view.addSubview(fbLoginButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print(fbLoginStatus())
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print(fbLoginStatus())
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("logged out")
    }
    
    func fbLoginStatus() -> String {
        if FBSDKAccessToken.current() != nil {
            return "logged in via facebook"
        } else {
            return "not logged in via facebook"
        }
    }

}

