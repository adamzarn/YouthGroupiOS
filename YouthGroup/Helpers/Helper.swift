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
        formatter.dateFormat = "yyyyMMdd HH:mm:ss:SSS"
        let stringDate = formatter.string(from: date)
        return stringDate
    }
    
    static func formattedTimestamp(ts: String, includeDate: Bool, includeTime: Bool) -> String {
        let year = ts.substring(with: 2..<4)
        let month = Int(ts.substring(with: 4..<6))
        let day = Int(ts.substring(with: 6..<8))
        var hour = Int(ts.substring(with: 9..<11))
        let minute = ts.substring(with: 12..<14)
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
        let minute = ts.substring(with: 3..<5)
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
    
    static func isLeader(group: Group) -> Bool {
        if let leaders = group.leaders {
            let leaderEmails = leaders.map { $0.email }
            if let email = Auth.auth().currentUser?.email {
                return leaderEmails.contains(where: { $0 == email })
            }
        }
        return false
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
