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
            let value = ["name": displayName]
            userRef.setValue(value) { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func addProfilePhoto(email: String, data: Data, completion: @escaping (_ error: String?) -> ()) {
        if let encodedEmail = email.encodeURIComponent() {
            let imageRef = self.storageRef.child("\(encodedEmail).jpg")
            imageRef.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(error.localizedDescription)
                }
                completion(nil)
            }
        } else {
            completion("Could not encode your email")
        }
    }
    
    func getProfilePhoto(email: String, completion: @escaping (_ image: Data?, _ error: String?) -> ()) {
        if let encodedEmail = email.encodeURIComponent() {
            let imageRef = self.storageRef.child("\(encodedEmail).jpg")
            imageRef.downloadURL(completion: { (url, error) in
                if let url = url {
                    DispatchQueue.global(qos: .background).async {
                        do {
                            let data = try Data(contentsOf: url)
                            completion(data, nil)
                        } catch {
                            completion(nil, "Error")
                        }
                    }
                } else {
                    completion(nil, "Error")
                }
            })
        }
    }
    
    func hasProfilePhoto(email: String, completion: @escaping (_ hasPhoto: Bool) -> ()) {
        if let encodedEmail = email.encodeURIComponent() {
            let imageRef = self.storageRef.child("\(encodedEmail).jpg")
            imageRef.getMetadata(completion: { (metadata, error) in
                if metadata != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        }
    }
    
    //MARK: Work with Groups
    
    func createGroup(group: Group, completion: @escaping (_ groupUID: String?, _ error: String?) -> ()) {
        let groupRef = ref.child("Groups").childByAutoId()
        groupRef.setValue(group.toAnyObject()) { (error, ref) -> Void in
            if let error = error {
                completion(nil, error.localizedDescription)
            } else {
                completion(groupRef.key, nil)
            }
        }
    }
    
    func editGroup(group: Group, completion: @escaping (_ error: String?) -> ()) {
        let groupRef = ref.child("Groups").child(group.uid!)
        groupRef.setValue(group.toAnyObject()) { (error, ref) -> Void in
            if let error = error {
                completion(error.localizedDescription)
            } else {
                completion(nil)
            }
        }
    }
    
    func getGroupUIDs(email: String, completion: @escaping (_ groupUIDs: [String]?) -> ()) {
        if let encodedEmail = email.encodeURIComponent() {
            let userRef = ref.child("Users").child(encodedEmail).child("groups")
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if let data = snapshot.value {
                    if data is NSNull {
                        completion(nil)
                    } else {
                        let groupUIDs = data as! [String]
                        completion(groupUIDs)
                    }
                } else {
                    completion(nil)
                }
            })
        }
    }
    
    func getGroup(groupUID: String, completion: @escaping (_ group: Group?) -> ()) {
        let groupRef = ref.child("Groups").child(groupUID)
        groupRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let uid = snapshot.key
                let info = snapshot.value as! NSDictionary
                completion(Group(uid: uid, info: info))
            } else {
                completion(nil)
            }
        })
    }
    
    func updateUserGroups(email: String, groupUIDs: [String], completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if let email = email.encodeURIComponent() {
            let userGroupsRef = ref.child("Users").child(email).child("groups")
            userGroupsRef.setValue(groupUIDs) { (error, ref) -> Void in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func updateGroupMembers(uid: String, updatedMembers: [Member], type: String, completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        let membersRef = ref.child("Groups").child(uid).child(type)
        membersRef.setValue(membersToAnyObject(members: updatedMembers)) { (error, ref) -> Void in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
    
    func membersToAnyObject(members: [Member]?) -> [String : String]? {
        if let members = members {
            var membersObject = [:] as [String:String]
            for member in members {
                if let email = member.email.encodeURIComponent(), let name = member.name {
                    membersObject[email] = name
                }
            }
            return membersObject
        }
        return nil
    }
    
    func queryGroups(query: String, searchKey: String, completion: @escaping (_ groups: [Group]?, _ error: String?) -> ()) {
        self.ref.child("Groups").queryOrdered(byChild: searchKey).queryStarting(atValue: query).queryLimited(toFirst: 20).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                if let groupsDict = (snapshot.value) {
                    var groups: [Group] = []
                    for (key, value) in groupsDict as! NSDictionary {
                        let uid = key as! String
                        let info = value as! NSDictionary
                        let group = Group(uid: uid, info: info)
                        groups.append(group)
                    }
                    completion(groups, nil)
                } else {
                    completion([], "Could not retrieve Group List")
                }
            }
        })
    }
    
    //MARK: Members
    
    //MARK: Prayer Requests
    
    func addPrayerRequest(prayerRequest: PrayerRequest, groupUID: String, completion: @escaping (_ error: String?) -> ()) {
        let prayerRequestRef = ref.child("PrayerRequests").child(groupUID).childByAutoId()
        prayerRequestRef.setValue(prayerRequest.toAnyObject()) { (error, ref) -> Void in
            if let error = error {
                completion(error.localizedDescription)
            } else {
                completion(nil)
            }
        }
    }
    
    func getPrayerRequests(groupUID: String, completion: @escaping (_ prayerRequests: [PrayerRequest]?) -> ()) {
        let groupRef = ref.child("PrayerRequests").child(groupUID)
        groupRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                var prayerRequests: [PrayerRequest] = []
                for child in snapshot.children {
                    let uid = (child as! DataSnapshot).key
                    let info = (child as! DataSnapshot).value as! NSDictionary
                    prayerRequests.append(PrayerRequest(uid: uid, info: info))
                }
                completion(prayerRequests)
            } else {
                completion(nil)
            }
        })
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
        let userData = [("Name",user.displayName),("Email",user.email),("ID",user.uid)]
        appDelegate.userData = userData as [(key: String, value: String?)]
    }
    
    func doesUserExist(email: String, completion: @escaping(_ userExists: Bool) -> ()) {
        if let encodedEmail = email.encodeURIComponent() {
            let userRef = self.ref.child("Users").child(encodedEmail)
            userRef.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    completion(true)
                } else {
                    completion(false)
                }
            })
        } else {
            completion(false)
        }
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
    
    func decodeURIComponent() -> String? {
        return self.removingPercentEncoding
    }

}
