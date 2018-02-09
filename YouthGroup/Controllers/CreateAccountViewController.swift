//
//  CreateAccountViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol CreateAccountViewControllerDelegate {
    func startLinkingEmailPasswordWithFacebookAccount(email: String)
}

class CreateAccountViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    var delegate: CreateAccountViewControllerDelegate?
    
    enum CreateAccountError: Error {
        case missingFirstName
        case missingLastName
        case missingEmail
        case missingPassword
        case passwordMismatch
    }
    var keyboardHeight: CGFloat?
    
    //MARK: IBOutlets
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordVerification: UITextField!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    //MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        KeyboardNotifications.subscribe(vc: self, showSelector: #selector(CreateAccountViewController.keyboardWillShow), hideSelector: #selector(CreateAccountViewController.keyboardWillHide))
        Aiv.hide(aiv: aiv)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        KeyboardNotifications.unsubscribe(vc: self)
    }
    
    //MARK: IBActions
    @IBAction func submitButtonPressed(_ sender: Any) {
        Aiv.show(aiv: aiv)
        do {
            try createUser()
        } catch CreateAccountError.missingFirstName {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "mfn"), message: getString(key: "mfn_m"), vc: self)
        } catch CreateAccountError.missingLastName {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "mln"), message: getString(key: "mln_m"), vc: self)
        } catch CreateAccountError.missingEmail {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "me"), message: getString(key: "me_m"), vc: self)
        } catch CreateAccountError.missingPassword {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "mp"), message: getString(key: "mp_m"), vc: self)
        } catch CreateAccountError.passwordMismatch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "pm"), message: getString(key: "pm_m"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "error"), message: getString(key: "ue_m"), vc: self)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func createUser() throws {
        if firstName.text!.isEmpty {
            throw CreateAccountError.missingFirstName
        }
        if lastName.text!.isEmpty {
            throw CreateAccountError.missingLastName
        }
        if email.text!.isEmpty {
            throw CreateAccountError.missingEmail
        }
        if password.text!.isEmpty {
            throw CreateAccountError.missingPassword
        }
        if password.text! != passwordVerification.text! {
            throw CreateAccountError.passwordMismatch
        }
        FirebaseClient.shared.createUser(email: email.text!, password: password.text!, completion: { (user, error) in
            if let user = user {
                let displayName = self.firstName.text!.trimmingCharacters(in: .whitespaces) + " " + self.lastName.text!.trimmingCharacters(in: .whitespaces)
                self.setDisplayName(user: user, displayName: displayName)
            }
            if let error = error {
                self.getProviders(email: self.email.text!, completion: { (providers) in
                    if let providers = providers {
                        if providers.contains("facebook.com") && !providers.contains("password") {
                            self.dismiss(animated: true, completion: nil)
                            self.delegate?.startLinkingEmailPasswordWithFacebookAccount(email: self.email.text!)
                        } else {
                            Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
                            Aiv.hide(aiv: self.aiv)
                        }
                    } else {
                        Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
                        Aiv.hide(aiv: self.aiv)
                    }
                })
            }
        })
    }
    
    func setDisplayName(user: User, displayName: String) {
        FirebaseClient.shared.setDisplayName(user: user, displayName: displayName, completion: { (error) in
            self.addNewUser(user: user)
            if let error = error {
                Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
            }
        })
    }
    
    func addNewUser(user: User) {
        if let email = user.email, let displayName = user.displayName {
            FirebaseClient.shared.addNewUser(email: email, displayName: displayName, completion: { (error) in
                Aiv.hide(aiv: self.aiv)
                FirebaseClient.shared.setUserData(user: user)
                if let error = error {
                    Alert.showBasicThenDismiss(title: self.getString(key: "error"), message: error, vc: self)
                } else {
                    Alert.showBasicThenDismiss(title: self.getString(key: "success"), message: self.getString(key: "asc"), vc: self)
                }
            })
        }
    }
    
    func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let keyboardHeight = KeyboardNotifications.getKeyboardHeight(notification: notification)
        if password.isFirstResponder || passwordVerification.isFirstResponder {
            view.frame.origin.y = (-1*keyboardHeight)/2
        }
        self.keyboardHeight = keyboardHeight
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        view.frame.origin.y = 0
    }

}

extension CreateAccountViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let keyboardHeight = keyboardHeight {
            if password.isFirstResponder || passwordVerification.isFirstResponder {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.view.frame.origin.y = (-1*keyboardHeight)/2
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.view.frame.origin.y = 0
                }, completion: nil)
            }
        }
    }
}

extension CreateAccountViewController {
    func getProviders(email: String, completion: @escaping (_ providers: [String]?) -> ()) {
        Auth.auth().fetchProviders(forEmail: email, completion: { (providers, error) in
            completion(providers)
        })
    }
}