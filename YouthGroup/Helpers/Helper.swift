//
//  Helper.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

class Helper {
    static func combineLeadersAndStudents(group: Group) -> [Member] {
        var members: [Member] = []
        if let leaders = group.leaders {
            let sortedLeaders = leaders.sorted(by: { $0.name < $1.name })
            for leader in sortedLeaders {
                let newMember = Member(email: leader.email, name: leader.name, leader: true)
                members.append(newMember)
            }
        }
        if let students = group.students {
            let sortedStudents = students.sorted(by: { $0.name < $1.name })
            for student in sortedStudents {
                let newMember = Member(email: student.email, name: student.name, leader: false)
                members.append(newMember)
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
