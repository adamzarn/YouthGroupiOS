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
        if Helper.hasConnectivity() {
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                if let user = user {
                    completion(user, nil)
                } else {
                    completion(nil, error?.localizedDescription)
                }
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func setDisplayName(user: User, displayName: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func addNewUser(email: String, displayName: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
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
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func addProfilePhoto(email: String, data: Data, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
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
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func getProfilePhoto(email: String, completion: @escaping (_ image: Data?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
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
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func hasProfilePhoto(email: String, completion: @escaping (_ hasPhoto: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let encodedEmail = email.encodeURIComponent() {
                let imageRef = self.storageRef.child("\(encodedEmail).jpg")
                imageRef.getMetadata(completion: { (metadata, error) in
                    if metadata != nil {
                        completion(true, nil)
                    } else {
                        completion(false, nil)
                    }
                })
            }
        } else {
            completion(false, Helper.getString(key: "noInternet"))
        }
    }
    
    //MARK: Work with Groups
    
    func createGroup(group: Group, completion: @escaping (_ groupUID: String?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let groupRef = ref.child("Groups").childByAutoId()
            groupRef.setValue(group.toAnyObject()) { (error, ref) -> Void in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    completion(groupRef.key, nil)
                }
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func editGroup(group: Group, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let groupRef = ref.child("Groups").child(group.uid!)
            groupRef.setValue(group.toAnyObject()) { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func getGroupUIDs(email: String, completion: @escaping (_ groupUIDs: [String]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let encodedEmail = email.encodeURIComponent() {
                let userRef = ref.child("Users").child(encodedEmail).child("groups")
                userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if let data = snapshot.value {
                        if data is NSNull {
                            completion(nil, nil)
                        } else {
                            let groupUIDs = data as! [String]
                            completion(groupUIDs, nil)
                        }
                    } else {
                        completion(nil, nil)
                    }
                })
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func getGroup(groupUID: String, completion: @escaping (_ group: Group?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let groupRef = ref.child("Groups").child(groupUID)
            groupRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let uid = snapshot.key
                    let info = snapshot.value as! NSDictionary
                    completion(Group(uid: uid, info: info), nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func updateUserGroups(email: String, groupUIDs: [String], completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
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
        } else {
            completion(false, Helper.getString(key: "noInternet"))
        }
    }
    
    func updateGroupMembers(uid: String, updatedMembers: [Member], type: String, completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let membersRef = ref.child("Groups").child(uid).child(type)
            membersRef.setValue(membersToAnyObject(members: updatedMembers)) { (error, ref) -> Void in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        } else {
            completion(false, Helper.getString(key: "noInternet"))
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
        if Helper.hasConnectivity() {
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
                        completion(nil, "Could not retrieve Group List")
                    }
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    //MARK: Members
    
    //MARK: Prayer Requests
    
    func addPrayerRequest(prayerRequest: PrayerRequest, groupUID: String, completion: @escaping (_ prayerRequestUID: String?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayerRequestRef = ref.child("PrayerRequests").child(groupUID).childByAutoId()
            prayerRequestRef.setValue(prayerRequest.toAnyObject()) { (error, ref) -> Void in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    completion(prayerRequestRef.key, nil)
                }
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func toggleAnswered(groupUID: String, prayerRequestUID: String, newStatus: Bool, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayerRequestRef = ref.child("PrayerRequests").child(groupUID).child(prayerRequestUID).child("answered")
            prayerRequestRef.setValue(newStatus) { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func updatePrayingMembers(groupUID: String, prayerRequestUID: String, prayingMembers: [Member], completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayerRequestRef = ref.child("PrayerRequests").child(groupUID).child(prayerRequestUID).child("prayingMembers")
            prayerRequestRef.setValue(Helper.convertMembersToAnyObject(members: prayingMembers)) { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func deletePrayerRequest(groupUID: String, prayerRequestUID: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayerRequestRef = ref.child("PrayerRequests").child(groupUID).child(prayerRequestUID)
            prayerRequestRef.removeValue() { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func getPrayerRequests(groupUID: String, completion: @escaping (_ prayerRequests: [PrayerRequest]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let groupRef = ref.child("PrayerRequests").child(groupUID)
            groupRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    var prayerRequests: [PrayerRequest] = []
                    for child in snapshot.children {
                        let uid = (child as! DataSnapshot).key
                        let info = (child as! DataSnapshot).value as! NSDictionary
                        prayerRequests.append(PrayerRequest(uid: uid, info: info))
                    }
                    completion(prayerRequests, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    //MARK: Sign in and out
    
    func signInWithEmailPassword(email: String, password: String, completion: @escaping (_ user: User?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                if let user = user {
                    completion(user, nil)
                } else {
                    completion(nil, error?.localizedDescription)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func signInWith(credential: AuthCredential, completion: @escaping (_ user: User?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if let user = user {
                    completion(user, nil)
                } else {
                    completion(nil, error?.localizedDescription)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func signOut(completion: @escaping(_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            do {
                try Auth.auth().signOut()
                completion(true, nil)
            } catch {
                completion(false, nil)
            }
        } else {
            completion(false, Helper.getString(key: "noInternet"))
        }
    }
    
    func setUserData(user: User) {
        let userData = [("Name",user.displayName),("Email",user.email),("ID",user.uid)]
        appDelegate.userData = userData as [(key: String, value: String?)]
    }
    
    func doesUserExist(email: String, completion: @escaping(_ userExists: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let encodedEmail = email.encodeURIComponent() {
                let userRef = self.ref.child("Users").child(encodedEmail)
                userRef.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists() {
                        completion(true, nil)
                    } else {
                        completion(false, nil)
                    }
                })
            } else {
                completion(false, nil)
            }
        } else {
            completion(true, Helper.getString(key: "noInternet"))
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
