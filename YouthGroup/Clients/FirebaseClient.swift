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
    
    func answerMultipleChoiceQuestion(groupUID: String, lessonUID: String, elementUID: String, correct: Bool, answerer: Answerer, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
            var answerRef: DatabaseReference!
            let email = answerer.email.encodeURIComponent()!
            if correct {
                answerRef = elementRef.child("correctMembers").child(email)
            } else {
                answerRef = elementRef.child("incorrectMembers").child(email)
            }
            answerRef.setValue(answerer.toAnyObject()) { (error, ref) -> Void in
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
    
    func answerFreeResponseQuestion(groupUID: String, lessonUID: String, elementUID: String, answerer: Answerer, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
            var answerRef: DatabaseReference!
            let email = answerer.email.encodeURIComponent()!
            answerRef = elementRef.child("answerers").child(email)
            answerRef.setValue(answerer.toAnyObject()) { (error, ref) -> Void in
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
    
    func getMultipleChoiceAnswerers(groupUID: String, lessonUID: String, elementUID: String, completion: @escaping (_ correctMembers: [Answerer]?, _ incorrectMembers: [Answerer]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
            elementRef.observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    var correctMembers: [Answerer]?
                    var incorrectMembers: [Answerer]?
                    let info = snapshot.value as! NSDictionary
                    if let correctAnswerers = info["correctMembers"] as? [String: [String:Any]] {
                        correctMembers = Helper.convertAnyObjectToAnswerers(dict: correctAnswerers, leader: false)
                    }
                    if let incorrectAnswerers = info["incorrectMembers"] as? [String: [String:Any]] {
                        incorrectMembers = Helper.convertAnyObjectToAnswerers(dict: incorrectAnswerers, leader: false)
                    }
                    completion(correctMembers, incorrectMembers, nil)
                } else {
                    completion(nil, nil, nil)
                }
            })
        } else {
            completion(nil, nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func getFreeResponseAnswerers(groupUID: String, lessonUID: String, elementUID: String, completion: @escaping (_ answerers: [Answerer]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let elementRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID)
            elementRef.observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    let info = snapshot.value as! NSDictionary
                    var answerers: [Answerer]?
                    if let correctAnswerers = info["answerers"] as? [String: [String: Any]] {
                        answerers = Helper.convertAnyObjectToAnswerers(dict: correctAnswerers, leader: false)
                    }
                    completion(answerers, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func deleteFreeResponseAnswer(groupUID: String, lessonUID: String, elementUID: String, email: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let answerRef = ref.child("Lessons").child(groupUID).child(lessonUID).child("elements").child(elementUID).child("answerers").child(email.encodeURIComponent()!)
            answerRef.removeValue() { (error, ref) -> Void in
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
    
    func checkInToLesson(groupUID: String, lessonUID: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let member = Helper.createMemberFromUser() {
                let checkedInRef = ref.child("CheckIns").child(groupUID).child(lessonUID).child(member.email.encodeURIComponent()!)
                checkedInRef.setValue(["name": member.name]) { (error, ref) -> Void in
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
    
    func checkOutOfLesson(groupUID: String, lessonUID: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            if let member = Helper.createMemberFromUser() {
                let checkedInRef = ref.child("CheckIns").child(groupUID).child(lessonUID).child(member.email.encodeURIComponent()!)
                checkedInRef.removeValue() { (error, ref) -> Void in
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
    
    func getCheckedInMembers(groupUID: String, lessonUID: String, completion: @escaping (_ checkedInMembers: [Member]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let checkedInRef = ref.child("CheckIns").child(groupUID).child(lessonUID)
            checkedInRef.observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    let dict = snapshot.value as! [String: [String: String]]
                    let checkedInMembers = Helper.convertAnyObjectToMembers(dict: dict, leader: false)
                    completion(checkedInMembers, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    //MARK: Posts
    
    func queryPosts(node: String, uid: String, start: Int64?, completion: @escaping (_ results: [Post]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            var postsQuery: DatabaseQuery?
            if let start = start {
                postsQuery = self.ref.child(node).child(uid).queryOrdered(byChild: "timestamp").queryStarting(atValue: start).queryLimited(toFirst: QueryLimits.posts)
            } else {
                postsQuery = self.ref.child(node).child(uid).queryOrdered(byChild: "timestamp").queryLimited(toFirst: QueryLimits.posts)
            }
            postsQuery?.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    if let postsDict = (snapshot.value) {
                        var posts: [Post] = []
                        for (key, value) in postsDict as! NSDictionary {
                            let uid = key as! String
                            let info = value as! NSDictionary
                            let post = Post(uid: uid, info: info)
                            posts.append(post)
                        }
                        completion(posts, nil)
                    } else {
                        completion([], nil)
                    }
                } else {
                    completion([], nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func observeNewPosts(node: String, uid: String, completion: @escaping (_ result: Post?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let postsQuery = self.ref.child(node).child(uid).queryLimited(toLast: 1)
            postsQuery.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    let post = Post(uid: snapshot.key, info: snapshot.value as! NSDictionary)
                    completion(post, nil)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func removeObservers(node: String, uid: String) {
        ref.child(node).child(uid).removeAllObservers()
    }
    
    func doesRefExist(node: String, uid: String, completion: @escaping (_ exists: Bool) -> ()) {
        let ref = self.ref.child(node).child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func pushPost(groupUID: String, post: Post, completion: @escaping (_ postUID: String?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            var postRef: DatabaseReference!
            if let postUID = post.uid {
                postRef = ref.child("Posts").child(groupUID).child(postUID)
            } else {
                postRef = ref.child("Posts").child(groupUID).childByAutoId()
            }
            postRef.setValue(post.toAnyObject()) { (error, ref) -> Void in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    completion(postRef.key, nil)
                }
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
        }
    }
    
    func pushComment(originalPostUID: String, comment: Post, completion: @escaping (_ postUID: String?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            var commentRef: DatabaseReference!
            if let commentUID = comment.uid {
                commentRef = ref.child("Comments").child(originalPostUID).child(commentUID)
            } else {
                commentRef = ref.child("Comments").child(originalPostUID).childByAutoId()
            }
            commentRef.setValue(comment.toAnyObject()) { (error, ref) -> Void in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    completion(commentRef.key, nil)
                }
            }
        } else {
            completion(nil, Helper.getString(key: "noInternet"))
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
    
    func deleteRSVP(groupUID: String, eventUID: String, rsvp: String, email: String, completion: @escaping (_ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let rsvpRef = ref.child("Events").child(groupUID).child(eventUID).child(rsvp).child(email.encodeURIComponent()!)
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
    
    func queryEvents(groupUID: String, start: String?, end: String?, completion: @escaping (_ events: [Event]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            var eventsQuery: DatabaseQuery?
            if let start = start {
                eventsQuery = self.ref.child("Events").child(groupUID).queryOrdered(byChild: "date").queryStarting(atValue: start).queryLimited(toFirst: QueryLimits.events)
            } else if let end = end {
                eventsQuery = self.ref.child("Events").child(groupUID).queryOrdered(byChild: "date").queryEnding(atValue: end).queryLimited(toLast: QueryLimits.events)
            }
            eventsQuery?.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    var events: [Event] = []
                    for child in snapshot.children {
                        let uid = (child as! DataSnapshot).key
                        let info = (child as! DataSnapshot).value as! NSDictionary
                        events.append(Event(uid: uid, info: info))
                    }
                    completion(events, nil)
                } else {
                    completion([], nil)
                }
            })
        } else {
            completion([], Helper.getString(key: "noInternet"))
        }
    }
    
    func observeNewEvents(groupUID: String, completion: @escaping (_ event: Event?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let eventQuery = self.ref.child("Events").child(groupUID).queryLimited(toLast: 1)
            eventQuery.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    let event = Event(uid: snapshot.key, info: snapshot.value as! NSDictionary)
                    completion(event, nil)
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
    
    func pushPrayerRequest(prayerRequest: PrayerRequest, groupUID: String, completion: @escaping (_ prayerRequestUID: String?, _ error: String?) -> ()) {
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
    
    func queryPrayerRequests(groupUID: String, start: Int64?, completion: @escaping (_ prayerRequests: [PrayerRequest]?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            var prayerRequestsQuery: DatabaseQuery?
            if let start = start {
                prayerRequestsQuery = self.ref.child("PrayerRequests").child(groupUID).queryOrdered(byChild: "timestamp").queryStarting(atValue: start).queryLimited(toFirst: QueryLimits.prayerRequests)
            } else {
                prayerRequestsQuery = self.ref.child("PrayerRequests").child(groupUID).queryOrdered(byChild: "timestamp").queryLimited(toFirst: QueryLimits.prayerRequests)
            }
            prayerRequestsQuery?.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    var prayerRequests: [PrayerRequest] = []
                    for child in snapshot.children {
                        let uid = (child as! DataSnapshot).key
                        let info = (child as! DataSnapshot).value as! NSDictionary
                        prayerRequests.append(PrayerRequest(uid: uid, info: info))
                    }
                    completion(prayerRequests, nil)
                } else {
                    completion([], nil)
                }
            })
        } else {
            completion([], Helper.getString(key: "noInternet"))
        }
    }
    
    func observeNewPrayerRequests(groupUID: String, completion: @escaping (_ prayerRequest: PrayerRequest?, _ error: String?) -> ()) {
        if Helper.hasConnectivity() {
            let prayerRequestQuery = self.ref.child("PrayerRequests").child(groupUID).queryLimited(toLast: 1)
            prayerRequestQuery.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    let prayerRequest = PrayerRequest(uid: snapshot.key, info: snapshot.value as! NSDictionary)
                    completion(prayerRequest, nil)
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
    
    func getChurchName(groupUID: String, completion: @escaping (_ churchName: String?) -> ()) {
        let churchRef = ref.child("Groups").child(groupUID).child("church")
        churchRef.observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot.value as? String)
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
    
    func decodeURIComponent() -> String? {
        return self.removingPercentEncoding
    }

}
