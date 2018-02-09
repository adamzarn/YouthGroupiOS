//
//  LoginViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/7/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, CreateAccountViewControllerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    var linkingInProgress = false
    var waitingForFacebook = false
    var fbCredentialForLinking: AuthCredential?
    
    enum LoginError: Error {
        case missingEmail
        case missingPassword
    }

    //MARK: IBOutlets
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fbLoginButton.readPermissions = ["public_profile", "email"]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        KeyboardNotifications.subscribe(vc: self, showSelector: #selector(LoginViewController.keyboardWillShow), hideSelector: #selector(LoginViewController.keyboardWillHide))
        Aiv.hide(aiv: aiv)
        if Auth.auth().currentUser != nil && !linkingInProgress && !waitingForFacebook {
            dismiss()
        } else {
            email.text = defaults.value(forKey: "lastUsedEmail") as? String
            password.text = defaults.value(forKey: "lastUsedPassword") as? String
        }
        if linkingInProgress {
            Aiv.show(aiv: aiv)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        KeyboardNotifications.unsubscribe(vc: self)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if FBSDKAccessToken.current() != nil {
            self.waitingForFacebook = true
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FirebaseClient.shared.signInWith(credential: credential, completion: { (user, error) in
                self.waitingForFacebook = false
                if let errorString = error {
                    FacebookClient.shared.getFBUserEmail(completion: { (email) in
                        if let email = email {
                            self.getProviders(email: email, completion: { (providers) in
                                if let providers = providers {
                                    if providers.contains("password") {
                                        self.fbCredentialForLinking = credential
                                        self.startLinkingFacebookWithEmailPasswordAccount(email: email)
                                    } else {
                                        Alert.showBasic(title: "Error", message: errorString, vc: self)
                                        Aiv.hide(aiv: self.aiv)
                                    }
                                } else {
                                    Alert.showBasic(title: "Error", message: errorString, vc: self)
                                    Aiv.hide(aiv: self.aiv)
                                }
                            })
                        } else {
                            Alert.showBasic(title: "Error", message: "Could not retrieve Facebook Email", vc: self)
                            Aiv.hide(aiv: self.aiv)
                        }
                    })
                } else {
                    if self.linkingInProgress {
                        self.linkEmailPasswordWithFacebookAccount(user: user!)
                    } else {
                        self.linkingInProgress = false
                        FirebaseClient.shared.setUserData(user: user!)
                        self.dismiss()
                    }
                }
            })
        }
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        Aiv.show(aiv: aiv)
        return true
    }
    
    func addNewUser(user: User) {
        if let email = user.email, let displayName = user.displayName {
            FirebaseClient.shared.addNewUser(email: email, displayName: displayName, completion: { (error) in
                Aiv.hide(aiv: self.aiv)
                if let error = error {
                    Alert.showBasicThenDismiss(title: self.getString(key: "error"), message: error, vc: self)
                } else {
                    Alert.showBasicThenDismiss(title: self.getString(key: "success"), message: self.getString(key: "asc"), vc: self)
                }
            })
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
    }
    
    func login() throws {
        if email.text!.isEmpty {
            throw LoginError.missingEmail
        }
        if password.text!.isEmpty {
            throw LoginError.missingPassword
        }
        signIn(email: email.text!, password: password.text!)
    }
    
    func signIn(email: String, password: String) {
        FirebaseClient.shared.signInWithEmailPassword(email: email, password: password, completion: { (user, error) in
            if let errorString = error {
                self.getProviders(email: email, completion: { (providers) in
                    if let providers = providers {
                        if providers.contains("facebook.com") {
                            self.startLinkingEmailPasswordWithFacebookAccount(email: email)
                        } else {
                            Alert.showBasic(title: "Error", message: errorString, vc: self)
                            Aiv.hide(aiv: self.aiv)
                        }
                    } else {
                        Alert.showBasic(title: "Error", message: errorString, vc: self)
                        Aiv.hide(aiv: self.aiv)
                    }
                })
            }
            if let user = user {
                if self.linkingInProgress {
                    self.linkFacebookWithEmailPasswordAccount(user: user)
                } else {
                    self.defaults.setValue(self.email.text!, forKey: "lastUsedEmail")
                    self.defaults.setValue(self.password.text!, forKey: "lastUsedPassword")
                    FirebaseClient.shared.setUserData(user: user)
                    self.dismiss()
                }
            }
        })
    }

    //MARK: IBActions
    @IBAction func loginButtonPressed(_ sender: Any) {
        Aiv.show(aiv: aiv)
        do {
            try login()
        } catch LoginError.missingEmail {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "me"), message: getString(key: "me_m"), vc: self)
        } catch LoginError.missingPassword {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "mp"), message: getString(key: "mp_m"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "error"), message: getString(key: "ue_m"), vc: self)
        }
    }
    
    @IBAction func createAccountButtonPressed(_ sender: Any) {
        let createAccountNC = storyboard?.instantiateViewController(withIdentifier: "CreateAccountNavigationController") as! UINavigationController
        let createAccountVC = createAccountNC.viewControllers[0] as! CreateAccountViewController
        createAccountVC.delegate = self
        present(createAccountNC, animated: true, completion: nil)
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        view.frame.origin.y = (-1*KeyboardNotifications.getKeyboardHeight(notification: notification))/2
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        view.frame.origin.y = 0
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}



