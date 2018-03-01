//
//  Linking.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import UIKit
import FirebaseAuth

//Link Facebook to existing Email/Password Account
extension LoginViewController {
    
    func startLinkingFacebookWithEmailPasswordAccount(email: String) {
        linkingInProgress = true
        let alert = UIAlertController(title: Helper.getString(key: "Email in Use"), message: Helper.getString(key: "linkWithFacebook"), preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = Helper.getString(key: "password");
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: Helper.getString(key: "link"), style: .default) { (_) in
            if let field = alert.textFields?[0] {
                self.password.text = field.text
                self.loginButton.sendActions(for: .touchUpInside)
            }
        })
        alert.addAction(UIAlertAction(title: Helper.getString(key: "cancel"), style: .cancel) { (_) in
            self.linkingInProgress = false
            Aiv.hide(aiv: self.aiv)
        })
        present(alert, animated: false, completion: nil)
    }
    
    func linkFacebookWithEmailPasswordAccount(user: User) {
        if let credential = fbCredentialForLinking {
            user.link(with: credential) { (user, error) in
                self.linkingInProgress = false
                self.fbCredentialForLinking = nil
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error.localizedDescription, vc: self)
                    Aiv.hide(aiv: self.aiv)
                } else {
                    FirebaseClient.shared.setUserData(user: user!)
                    self.checkForPhoto(user: user!)
                }
            }
        }
    }
    
}

//Link Email/Password to existing Facebook Account
extension LoginViewController {
    
    func startLinkingEmailPasswordWithFacebookAccount(email: String) {
        linkingInProgress = true
        let alert = UIAlertController(title: Helper.getString(key: "emailInUse"), message: Helper.getString(key: "linkWithYouthGroup"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Helper.getString(key: "link"), style: .default) { (_) in
            self.defaults.setValue(self.email.text!, forKey: "lastUsedEmail")
            self.defaults.setValue(self.password.text!, forKey: "lastUsedPassword")
            self.fbLoginButton.sendActions(for: .touchUpInside)
        })
        alert.addAction(UIAlertAction(title: Helper.getString(key: "cancel"), style: .cancel) { (_) in
            self.linkingInProgress = false
            Aiv.hide(aiv: self.aiv)
        })
        present(alert, animated: false, completion: nil)
    }
    
    func linkEmailPasswordWithFacebookAccount(user: User) {
        let credential = EmailAuthProvider.credential(withEmail: self.email.text!, password: self.password.text!)
        user.link(with: credential) { (user, error) in
            self.linkingInProgress = false
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error.localizedDescription, vc: self)
                Aiv.hide(aiv: self.aiv)
            } else {
                FirebaseClient.shared.setUserData(user: user!)
                self.checkForPhoto(user: user!)
            }
        }
    }
    
}

extension LoginViewController {
    func getProviders(email: String, completion: @escaping (_ providers: [String]?) -> ()) {
        Auth.auth().fetchProviders(forEmail: email, completion: { (providers, error) in
            completion(providers)
        })
    }
    
    func checkForPhoto(user: User) {
        FirebaseClient.shared.hasProfilePhoto(email: user.email!, completion: { (hasPhoto, error) in
            Aiv.hide(aiv: self.aiv)
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if hasPhoto {
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: Helper.getString(key: "accountsLinked"), vc: self, completion: {_ in self.navigationController?.dismiss(animated: true, completion: nil)
                    })
                } else {
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: Helper.getString(key: "accountsLinked"), vc: self, completion: {_ in
                        let addPhotoVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPhotoViewController") as! AddPhotoViewController
                        self.navigationController?.pushViewController(addPhotoVC, animated: true)
                    })
                }
            }
        })
    }
    
}
