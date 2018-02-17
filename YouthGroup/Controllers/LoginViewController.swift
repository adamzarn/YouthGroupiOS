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

protocol LoginViewControllerDelegate: class {
    func refreshAccountDetail(reloadGroupsOnly: Bool)
}

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, CreateAccountViewControllerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    var linkingInProgress = false
    var waitingForFacebook = false
    var fbCredentialForLinking: AuthCredential?
    
    weak var delegate: LoginViewControllerDelegate?

    //MARK: IBOutlets
    @IBOutlet weak var titleView: BouncingView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fbLoginButton.readPermissions = ["public_profile", "email"]
        titleView.animating = true
        titleView.isHidden = false
        titleView.animateTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        KeyboardNotifications.subscribe(vc: self, showSelector: #selector(LoginViewController.keyboardWillShow), hideSelector: #selector(LoginViewController.keyboardWillHide))
        Aiv.hide(aiv: aiv)
        if Auth.auth().currentUser != nil && !linkingInProgress && !waitingForFacebook {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            email.text = defaults.value(forKey: "lastUsedEmail") as? String
            password.text = defaults.value(forKey: "lastUsedPassword") as? String
        }
        if linkingInProgress {
            Aiv.show(aiv: aiv)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        KeyboardNotifications.unsubscribe(vc: self)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if FBSDKAccessToken.current() != nil {
            waitingForFacebook = true
            fbCredentialForLinking = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            signInWithFacebook(credential: fbCredentialForLinking!)
        }
    }
    
    func signInWithFacebook(credential: AuthCredential) {
        FirebaseClient.shared.signInWith(credential: credential, completion: { (user, error) in
            self.waitingForFacebook = false
            if let errorString = error {
                self.checkIfLinkIsNecessary(error: errorString)
            } else {
                if self.linkingInProgress {
                    self.linkEmailPasswordWithFacebookAccount(user: user!)
                } else {
                    FirebaseClient.shared.setUserData(user: user!)
                    if self.defaults.bool(forKey: "loggedInWithFacebookBefore") {
                        self.delegate?.refreshAccountDetail(reloadGroupsOnly: false)
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    } else {
                        self.addNewUser(user: user!)
                    }
                }
            }
        })
    }
    
    func checkIfLinkIsNecessary(error: String) {
        FacebookClient.shared.getFBUserEmail(completion: { (email) in
            if let email = email {
                self.getProviders(email: email, completion: { (providers) in
                    if let providers = providers, providers.contains("password") {
                        self.startLinkingFacebookWithEmailPasswordAccount(email: email)
                    } else {
                        Alert.showBasic(title: "Error", message: error, vc: self)
                        Aiv.hide(aiv: self.aiv)
                    }
                })
            } else {
                Alert.showBasic(title: "Error", message: "Could not retrieve Facebook Email", vc: self)
                Aiv.hide(aiv: self.aiv)
            }
        })
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
                    Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
                } else {
                    self.defaults.set(true, forKey: "loggedInWithFacebookBefore")
                    let addPhotoVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPhotoViewController") as! AddPhotoViewController
                    self.navigationController?.pushViewController(addPhotoVC, animated: true)
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
                    self.defaults.setValue(self.email.text!.lowercased(), forKey: "lastUsedEmail")
                    self.defaults.setValue(self.password.text!, forKey: "lastUsedPassword")
                    FirebaseClient.shared.setUserData(user: user)
                    self.delegate?.refreshAccountDetail(reloadGroupsOnly: false)
                    self.navigationController?.dismiss(animated: true, completion: nil)
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
        let createAccountVC = storyboard?.instantiateViewController(withIdentifier: "CreateAccountViewController") as! CreateAccountViewController
        createAccountVC.delegate = self
        self.navigationController?.pushViewController(createAccountVC, animated: true)
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



