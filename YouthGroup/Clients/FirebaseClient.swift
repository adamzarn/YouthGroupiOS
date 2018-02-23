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
    
    //MARK: Groups
    
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
                            let groupUIDs = (data as! NSDictionary).allKeys as! [String]
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
    
    func getGroupLeaders(groupUID: String, completion: @escaping (_ leaders: [Member]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let leadersRef = ref.child("Groups").child(groupUID).child("leaders")
            leadersRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let dict = snapshot.value as! [String: [String: String]]
                    let leaders = Helper.convertAnyObjectToMembers(dict: dict, leader: true)
                    completion(leaders, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }

    
    func appendUserGroup(email: String, newGroupUID: String, completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let email = email.encodeURIComponent() {
                let groupToAppendRef = ref.child("Users").child(email).child("groups").child(newGroupUID)
                groupToAppendRef.setValue(true) { (error, ref) -> Void in
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
    
    func deleteUserGroup(email: String, groupUIDToDelete: String, completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let email = email.encodeURIComponent() {
                let groupToDeleteRef = ref.child("Users").child(email).child("groups").child(groupUIDToDelete)
                groupToDeleteRef.removeValue() { (error, ref) -> Void in
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
    
    func appendGroupMember(uid: String, newMember: Member, type: String, completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let memberRef = ref.child("Groups").child(uid).child(type).child(newMember.email.encodeURIComponent()!)
            let value = ["name": newMember.name]
            memberRef.setValue(value) { (error, ref) -> Void in
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
    
    func deleteGroupMember(uid: String, email: String, type: String, completion: @escaping (_ success: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let memberToDeleteRef = ref.child("Groups").child(uid).child(type).child(email.encodeURIComponent()!)
            memberToDeleteRef.removeValue() { (error, ref) -> Void in
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
    
    //MARK: Lessons
    
    func createLesson(groupUID: String, lesson: Lesson, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let lessonRef = ref.child("Lessons").child(groupUID).childByAutoId()
            lessonRef.setValue(lesson.toAnyObject()) { (error, ref) -> Void in
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
    
    func editLesson(groupUID: String, lesson: Lesson, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let lessonRef = ref.child("Lessons").child(groupUID).child(lesson.uid!)
            lessonRef.setValue(lesson.toAnyObject()) { (error, ref) -> Void in
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
    
    func deleteLesson(groupUID: String, lessonUID: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let lessonRef = ref.child("Lessons").child(groupUID).child(lessonUID)
            lessonRef.removeValue() { (error, ref) -> Void in
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
    
    func getLessons(groupUID: String, completion: @escaping (_ lessons: [Lesson]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let lessonsRef = ref.child("Lessons").child(groupUID)
            lessonsRef.observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    var lessons: [Lesson] = []
                    for child in snapshot.children {
                        let uid = (child as! DataSnapshot).key
                        let info = (child as! DataSnapshot).value as! NSDictionary
                        lessons.append(Lesson(uid: uid, info: info))
                    }
                    completion(lessons, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func pushElement(groupUID: String, lessonUID: String, element: LessonElement, completion: @escaping (_ error: String?, _ successMessage: String?) -> ()) {
        if Helper.hasConnectivity() {
            var elementRef: DatabaseReference
            var successMessage: String
            if let elementUID = element.uid {
                elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
                successMessage = Helper.getString(key: "editElementMessage")
            } else {
                elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").childByAutoId()
                successMessage = Helper.getString(key: "addElementMessage")
            }

            var value: [String: Any]? = nil
            switch element.type {
            case Elements.activity.rawValue:
                value = (element as! Activity).toAnyObject()
            case Elements.passage.rawValue:
                value = (element as! Passage).toAnyObject()
            case Elements.multipleChoiceQuestion.rawValue:
                value = (element as! MultipleChoiceQuestion).toAnyObject()
            case Elements.freeResponseQuestion.rawValue:
                value = (element as! FreeResponseQuestion).toAnyObject()
            default:
                ()
            }
            elementRef.setValue(value) { (error, ref) -> Void in
                if let error = error {
                    completion(error.localizedDescription, nil)
                } else {
                    completion(nil, successMessage)
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"), nil)
        }
    }
    
    func deleteElement(groupUID: String, lessonUID: String, elementUID: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
            elementRef.removeValue()
            completion(nil)
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
            
    func getElements(groupUID: String, lessonUID: String, completion: @escaping (_ elements: [LessonElement]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementsRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements")
            elementsRef.observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    let dict = snapshot.value as! [String: [String: Any]]
                    let elements = Helper.convertAnyObjectToLessonElements(dict: dict)
                    completion(elements, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func setPosition(groupUID: String, lessonUID: String, elementUID: String, position: Int, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let positionRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID).child("position")
            positionRef.setValue(position)
            completion(nil)
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func answerMultipleChoiceQuestion(groupUID: String, lessonUID: String, elementUID: String, correct: Bool, answer: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
            var answerRef: DatabaseReference!
            if correct {
                answerRef = elementRef.child("correctMembers")
            } else {
                answerRef = elementRef.child("incorrectMembers")
            }
            if let member = Helper.createMemberFromUser() {
                let value = [member.email.encodeURIComponent()!: ["name": member.name, "answer": answer]]
                answerRef.setValue(value) { (error, ref) -> Void in
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
    
    //MARK: Events
    
    func updateRSVP(groupUID: String, eventUID: String, rsvp: String, bringer: Bringer, completion: @escaping (_ error: String?) -> ()) {
        let rsvps = ["going", "maybe", "notGoing"]
        let rsvpsToRemove = rsvps.filter { $0 != rsvp }
        if Helper.hasConnectivity() {
            if let email = bringer.email.encodeURIComponent() {
                let rsvpRef = ref.child("Events").child(groupUID).child(eventUID).child(rsvp).child(email)
                let value = ["name":bringer.name, "bringing": bringer.bringing]
                rsvpRef.setValue(value) { (error, ref) -> Void in
                    if let error = error {
                        completion(error.localizedDescription)
                    } else {
                        completion(nil)
                    }
                }
                for rsvpToRemove in rsvpsToRemove {
                    let rsvpsToRemoveRef = ref.child("Events").child(groupUID).child(eventUID).child(rsvpToRemove).child(email)
                    rsvpsToRemoveRef.removeValue()
                }
            }
        } else {
            completion(Helper.getString(key: "noInternet"))
        }
    }
    
    func removeRSVP(groupUID: String, eventUID: String, rsvp: String, bringer: Bringer, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let rsvpRef = ref.child("Events").child(groupUID).child(eventUID).child(rsvp).child(bringer.email)
            rsvpRef.removeValue() { (error, ref) -> Void in
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
    
    func createEvent(event: Event, groupUID: String, completion: @escaping (_ eventUID: String?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let eventRef = ref.child("Events").child(groupUID).childByAutoId()
            eventRef.setValue(event.toAnyObject()) { (error, ref) -> Void in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    completion(eventRef.key, nil)
                }
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func editEvent(groupUID: String, event: Event, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let eventRef = ref.child("Events").child(groupUID).child(event.uid!)
            eventRef.setValue(event.toAnyObject()) { (error, ref) -> Void in
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
    
    func getEvents(groupUID: String, completion: @escaping (_ events: [Event]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let eventsRef = ref.child("Events").child(groupUID)
            eventsRef.observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    var events: [Event] = []
                    for child in snapshot.children {
                        let uid = (child as! DataSnapshot).key
                        let info = (child as! DataSnapshot).value as! NSDictionary
                        events.append(Event(uid: uid, info: info))
                    }
                    completion(events, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func deleteEvent(groupUID: String, eventUID: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayerRequestRef = ref.child("Events").child(groupUID).child(eventUID)
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
    
    func appendPrayingMember(groupUID: String, prayerRequestUID: String, newPrayingMember: Member, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayingMemberRef = ref.child("PrayerRequests").child(groupUID).child(prayerRequestUID).child("prayingMembers").child(newPrayingMember.email.encodeURIComponent()!)
            let value = ["name":newPrayingMember.name]
            prayingMemberRef.setValue(value) { (error, ref) -> Void in
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
    
    func deletePrayingMember(groupUID: String, prayerRequestUID: String, prayingMemberToDelete: Member, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayingMemberToDeleteRef = ref.child("PrayerRequests").child(groupUID).child(prayerRequestUID).child("prayingMembers").child(prayingMemberToDelete.email.encodeURIComponent()!)
            prayingMemberToDeleteRef.removeValue() { (error, ref) -> Void in
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
            groupRef.queryOrdered(byChild: "timestamp").queryLimited(toLast: 50).observe(.value, with: { (snapshot) in
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
    
    func isLeader(groupUID: String, email: String, completion: @escaping(_ isLeader: Bool, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let encodedEmail = email.encodeURIComponent() {
                let leaderRef = ref.child("Groups").child(groupUID).child("leaders").child(encodedEmail)
                leaderRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        completion(true, nil)
                    } else {
                        completion(false, nil)
                    }
                })
            } else {
                completion(false, "Bad Email.")
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
