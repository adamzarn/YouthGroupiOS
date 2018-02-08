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
    
    func signIn(email: String, password: String, completion: @escaping (_ user: User?, _ error: String?) -> ()) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let user = user {
                completion(user, nil)
            } else {
                completion(nil, error?.localizedDescription)
            }
        }
    }
    
    func signOut(completion: @escaping(_ success: Bool) -> ()) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            completion(false)
        }
    }
    
    static let shared = FirebaseClient()
    private override init() {
        super.init()
    }
    
}
