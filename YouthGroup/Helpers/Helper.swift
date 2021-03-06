//
//  Helper.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import FirebaseAuth

class Helper {
    
    static func hasConnectivity() -> Bool {
        do {
            let reachability = Reachability()
            let networkStatus: Int = reachability!.currentReachabilityStatus.hashValue
            return (networkStatus != 0)
        }
    }
    
    static func createMemberFromUser() -> Member? {
        if let user = Auth.auth().currentUser, let email = user.email, let name = user.displayName {
            return Member(email: email, name: name, leader: false)
        }
        return nil
    }
    
    static func convertAnyObjectToBringers(dict: [String:[String: String]], leader: Bool) -> [Bringer] {
        var bringers: [Bringer] = []
        for (key,value) in dict {
            if let email = key.decodeURIComponent() {
                let name = value["name"]
                var bringing: String?
                if let bringingValue = value["bringing"] {
                    bringing = bringingValue
                }
                let newBringer = Bringer(email: email, name: name!, leader: leader, bringing: bringing)
                bringers.append(newBringer)
            }
        }
        return bringers
    }
    
    static func convertBringersToAnyObject(bringers: [Bringer]?) ->  [String: [String: String]]? {
        if let bringers = bringers {
            var bringersObject = [:] as [String: [String: String]]
            for bringer in bringers {
                if let email = bringer.email.encodeURIComponent() {
                    var value = [:] as [String: String]
                    value["name"] = bringer.name
                    if let bringing = bringer.bringing {
                        value["bringing"] = bringing
                    }
                    bringersObject[email] = value
                }
            }
            return bringersObject
        }
        return nil
    }
    
    static func convertAnyObjectToAddress(dict: NSDictionary) -> Address {
        let street = dict["street"] as! String
        let city = dict["city"] as! String
        let state = dict["state"] as! String
        let zip = dict["zip"] as! String
        return Address(street: street, city: city, state: state, zip: zip)
    }
    
    static func convertAddressToAnyObject(address: Address) -> [String: String] {
        return ["street": address.street,
                "city": address.city,
                "state": address.state,
                "zip": address.zip]
    }
    
    static func convertAnyObjectToMembers(dict: [String: [String:String]], leader: Bool) -> [Member] {
        var members: [Member] = []
        for (key,value) in dict {
            if let email = key.decodeURIComponent() {
                let name = value["name"] as! String
                let newMember = Member(email: email, name: name, leader: leader)
                members.append(newMember)
            }
        }
        return members
    }
    
    static func convertMembersToAnyObject(members: [Member]?) ->  [String: [String: String]]? {
        if let members = members {
            var membersObject = [:] as [String: [String: String]]
            for member in members {
                if let email = member.email.encodeURIComponent(), let name = member.name {
                    membersObject[email] = ["name": name]
                }
            }
            return membersObject
        }
        return nil
    }
    
    static func convertAnyObjectToPosts(dict: [String: [String: Any]]) -> [Post] {
        var posts: [Post] = []
        for (key, value) in dict {
            let uid = key
            let email = value["email"] as! String
            let name = value["name"] as! String
            let timestamp = value["email"] as! Int64
            let text = value["text"] as! String
            let post = Post(uid: uid, email: email, name: name, timestamp: timestamp, text: text)
            posts.append(post)
        }
        return posts
    }
    
    static func convertPostsToAnyObject(posts: [Post]?) ->  [String: [String: Any]]? {
        if let posts = posts {
            var postsObject = [:] as [String: [String: Any]]
            for post in posts {
                var value = [:] as [String: Any]
                value["email"] = post.email
                value["name"] = post.name
                value["timestamp"] = post.timestamp
                value["text"] = post.text
                postsObject[post.uid!] = value
            }
            return postsObject
        }
        return nil
    }
    
    static func convertAnyObjectToAnswerers(dict: [String: [String:Any]], leader: Bool) -> [Answerer] {
        var answerers: [Answerer] = []
        for (key,value) in dict {
            if let email = key.decodeURIComponent() {
                let name = value["name"] as! String
                let answer = value["answer"] as! String
                let timestamp = value["timestamp"] as! Int64
                let answerer = Answerer(email: email, name: name, leader: leader, answer: answer, timestamp: timestamp)
                answerers.append(answerer)
            }
        }
        return answerers
    }
    
    static func convertAnswerersToAnyObject(answerers: [Answerer]?) ->  [String: [String: Any]]? {
        if let answerers = answerers {
            var answerersObject = [:] as [String: [String: Any]]
            for answerer in answerers {
                if let email = answerer.email.encodeURIComponent(), let name = answerer.name {
                    answerersObject[email] = ["name": name, "answer": answerer.answer!, "timestamp": answerer.timestamp]
                }
            }
            return answerersObject
        }
        return nil
    }
    
    static func convertLessonElementsToAnyObject(elements: [LessonElement]?) -> [String: Any]? {
        if let elements = elements {
            var elementsObject = [:] as [String: Any]
            for element in elements {
                if element is Activity {
                    elementsObject[element.uid!] = (element as! Activity).toAnyObject()
                }
                if element is Passage {
                    elementsObject[element.uid!] = (element as! Passage).toAnyObject()
                }
                if element is MultipleChoiceQuestion {
                    elementsObject[element.uid!] = (element as! MultipleChoiceQuestion).toAnyObject()
                }
                if element is FreeResponseQuestion {
                    elementsObject[element.uid!] = (element as! FreeResponseQuestion).toAnyObject()
                }
            }
            return elementsObject
        }
        return nil
    }
    
    static func convertAnyObjectToLessonElements(dict: [String: [String:Any]]?) -> [LessonElement]? {
        if let dict = dict {
            var elements: [LessonElement] = []
            for (key, info) in dict {
                let uid = key
                let type = info["type"] as! Int
                switch type {
                case Elements.activity.rawValue:
                    elements.append(Activity(uid: uid, info: info))
                case Elements.passage.rawValue:
                    elements.append(Passage(uid: uid, info: info))
                case Elements.multipleChoiceQuestion.rawValue:
                    elements.append(MultipleChoiceQuestion(uid: uid, info: info))
                case Elements.freeResponseQuestion.rawValue:
                    elements.append(FreeResponseQuestion(uid: uid, info: info))
                default:
                    ()
                }
            }
            return elements
        }
        return nil
    }
    
    static func convertAnyObjectToStringArray(dict: [String: Bool]) -> [String] {
        var incorrectAnswers: [String] = []
        for (key, _) in dict {
            incorrectAnswers.append(key)
        }
        return incorrectAnswers
    }
    
    static func convertIncorrectAnswersToAnyObject(incorrectAnswers: [String]) -> [String: Bool]? {
        var object: [String: Bool] = [:]
        for incorrectAnswer in incorrectAnswers {
            object[incorrectAnswer] = true
        }
        return object
    }
    
    static func combineLeadersAndStudents(group: Group) -> [Member] {
        var members: [Member] = []
        if let leaders = group.leaders {
            let sortedLeaders = leaders.sorted(by: { $0.name < $1.name })
            for leader in sortedLeaders {
                let newLeader = Member(email: leader.email, name: leader.name, leader: true)
                members.append(newLeader)
            }
        }
        if let students = group.students {
            let sortedStudents = students.sorted(by: { $0.name < $1.name })
            for student in sortedStudents {
                let newStudent = Member(email: student.email, name: student.name, leader: false)
                members.append(newStudent)
            }
        }
        return members
    }
    
    static func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    static func getCurrentDateAndTime() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"
        let stringDate = formatter.string(from: date)
        return stringDate
    }
    
    static func formattedTimestamp(ts: String, includeDate: Bool, includeTime: Bool) -> String {
        var timestamp = ts
        if ts.count == 18 {
            timestamp = ts.substring(with: 1..<18)
        }
        let year = timestamp.substring(with: 2..<4)
        let month = Int(timestamp.substring(with: 4..<6))
        let day = Int(timestamp.substring(with: 6..<8))
        var hour = Int(timestamp.substring(with: 8..<10))
        let minute = timestamp.substring(with: 10..<12)
        var suffix = "AM"
        if hour! > 11 {
            suffix = "PM"
        }
        if hour! > 12 {
            hour = hour! - 12
        }
        if hour! == 0 {
            hour = 12
        }
        
        if includeDate && includeTime {
            return "\(month!)/\(day!)/\(year) \(hour!):\(minute) \(suffix)"
        } else if !includeDate && includeTime {
            return "\(hour!):\(minute) \(suffix)"
        } else if includeDate && !includeTime {
            return "\(month!)/\(day!)/\(year)"
        } else {
            return ""
        }
        
    }
    
    static func formattedDate(ts: String) -> String {
        let year = ts.substring(with: 2..<4)
        let month = Int(ts.substring(with: 4..<6))
        let day = Int(ts.substring(with: 6..<8))
        return "\(month!)/\(day!)/\(year)"
    }
    
    static func formattedTime(ts: String) -> String {
        var hour = Int(ts.substring(with: 0..<2))
        let minute = ts.substring(with: 2..<4)
        var suffix = "AM"
        if hour! > 11 {
            suffix = "PM"
        }
        if hour! > 12 {
            hour = hour! - 12
        }
        if hour! == 0 {
            hour = 12
        }
        return "\(hour!):\(minute) \(suffix)"

    }

    static let weekdays =
        [1 : "Sunday",
        2 :"Monday",
        3 : "Tuesday",
        4 : "Wednesday",
        5 : "Thursday",
        6 : "Friday",
        7 : "Saturday"]
    
    static func getDayOfWeek(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let date = formatter.date(from: dateString)!
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let myComponents = myCalendar.components(.weekday, from: date)
        let weekday = myComponents.weekday
        return weekdays[weekday!]!
    }
    
    static func getTodayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: Date())
    }
    
    static func isLeader(group: Group) -> Bool {
        if let leaders = group.leaders {
            let leaderEmails = leaders.map { $0.email }
            if let email = Auth.auth().currentUser?.email {
                return leaderEmails.contains(where: { $0 == email })
            }
        }
        return false
    }
    
    static func getCurrentAnswerer(correctMembers: [Answerer]?, incorrectMembers: [Answerer]?) -> Answerer? {
        var answerers: [Answerer] = []
        if let correctMembers = correctMembers {
            answerers += correctMembers
        }
        if let incorrectMembers = incorrectMembers {
            answerers += incorrectMembers
        }
        if let email = Auth.auth().currentUser?.email {
            let currentAnswerers = answerers.filter({ $0.email == email })
            if currentAnswerers.count > 0 {
                return currentAnswerers[0]
            } else {
                return nil
            }
        }
        return nil
    }
    
    static func setChurchName(groupUID: String, button: UIBarButtonItem) {
        FirebaseClient.shared.getChurchName(groupUID: groupUID, completion: { (churchName) in
            if let churchName = churchName {
                button.title = churchName
            }
        })
    }
    
}

extension String {
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
