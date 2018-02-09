//
//  FirebaseClient.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/7/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import Firebase

class FirebaseClient: NSObject {
    
    let ref = Database.database().reference()
    let storageRef = Storage.storage().reference()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: - Create a User
    
    func createUser(email: String, password: String, completion: @escaping (_ user: User?, _ error: String?) -> ()) {
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let user = user {
                completion(user, nil)
            } else {
                completion(nil, error?.localizedDescription)
            }
        }
    }
    
    func setDisplayName(user: User, displayName: String, completion: @escaping (_ error: String?) -> ()) {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        changeRequest.commitChanges { error in
            if let error = error {
                completion(error.localizedDescription)
            } else {
                completion(nil)
            }
        }
    }
    
    func addNewUser(email: String, displayName: String, completion: @escaping (_ error: String?) -> ()) {
        if let encodedEmail = email.encodeURIComponent() {
            let userRef = self.ref.child("Users/\(encodedEmail)")
            userRef.setValue(displayName) { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    //MARK: Sign in and out
    
    func signInWithEmailPassword(email: String, password: String, completion: @escaping (_ user: User?, _ error: String?) -> ()) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if let user = user {
                completion(user, nil)
            } else {
                completion(nil, error?.localizedDescription)
            }
        })
    }
    
    func signInWith(credential: AuthCredential, completion: @escaping (_ user: User?, _ error: String?) -> ()) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            if let user = user {
                completion(user, nil)
            } else {
                completion(nil, error?.localizedDescription)
            }
        })
    }
    
    func signOut(completion: @escaping(_ success: Bool) -> ()) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            completion(false)
        }
    }
    
    func setUserData(user: User) {
        let userData = [("ID",user.uid),("Email",user.email),("Name",user.displayName)]
        appDelegate.userData = userData as [(key: String, value: String?)]
    }
    
    func doesUserExist(email: String, completion: @escaping(_ userExits: Bool) -> ()) {
        let userRef = self.ref.child("Users/\(email.encodeURIComponent()!)")
        userRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    static let shared = FirebaseClient()
    private override init() {
        super.init()
    }
    
}

extension String {
    
    func encodeURIComponent() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-_!~*'()")
        return self.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
    }
    
}
