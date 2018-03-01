//
//  Group.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/15/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import Firebase

struct Group {
    
    var uid: String?
    var church: String!
    var lowercasedChurch: String!
    var nickname: String!
    var password: String!
    var createdBy: String!
    var lowercasedCreatedBy: String!
    var createdByEmail: String!
    var description: String?
    var leaders: [Member]?
    var students: [Member]?
    
    init(uid: String?, church: String, lowercasedChurch: String, nickname: String, password: String, createdBy: String, lowercasedCreatedBy: String, createdByEmail: String, description: String?, leaders: [Member]?, students: [Member]?) {
        self.uid = uid
        self.church = church
        self.lowercasedChurch = lowercasedChurch
        self.nickname = nickname
        self.password = password
        self.createdBy = createdBy
        self.lowercasedCreatedBy = lowercasedCreatedBy
        self.createdByEmail = createdByEmail
        self.description = description
        self.leaders = leaders
        self.students = students
    }
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.church = info["church"] as! String
        self.lowercasedChurch = info["lowercasedChurch"] as! String
        self.nickname = info["nickname"] as! String
        self.password = info["password"] as! String
        self.createdBy = info["createdBy"] as! String
        self.lowercasedCreatedBy = info["lowercasedCreatedBy"] as! String
        self.createdByEmail = info["createdByEmail"] as! String
        if let description = info["description"] {
            self.description = description as? String
        }
        if let leaders = info["leaders"] {
            self.leaders = Helper.convertAnyObjectToMembers(dict: leaders as! [String:[String : String]], leader: true)
        }
        if let students = info["students"] {
            self.students = Helper.convertAnyObjectToMembers(dict: students as! [String: [String : String]], leader: false)
        }
    }
    
    func toAnyObject() -> [String: Any] {
        return ["church": self.church,
                "lowercasedChurch": self.lowercasedChurch,
                "nickname": self.nickname,
                "password": self.password,
                "createdBy": self.createdBy,
                "lowercasedCreatedBy": self.lowercasedCreatedBy,
                "createdByEmail": self.createdByEmail,
                "description": self.description,
                "leaders": Helper.convertMembersToAnyObject(members: self.leaders),
                "students": Helper.convertMembersToAnyObject(members: self.students)]
    }
    
}

class Member {
    
    var email: String!
    var name: String!
    var leader: Bool?
    var groups: [Group]?
    
    init(email: String, name: String, leader: Bool?) {
        self.email = email
        self.name = name
        self.leader = leader
        self.groups = nil
    }
    
}

class Bringer: Member {
    var bringing: String?
    init(email: String, name: String, leader: Bool?, bringing: String?) {
        super.init(email: email, name: name, leader: leader)
        self.bringing = bringing
    }
}

class Answerer: Member {
    var answer: String!
    var timestamp: Int64!
    init(email: String, name: String, leader: Bool?, answer: String?, timestamp: Int64) {
        super.init(email: email, name: name, leader: leader)
        self.answer = answer
        self.timestamp = timestamp
    }
    
    func toAnyObject() -> [String: Any] {
        return ["name": name,
                "answer": answer,
                "timestamp": timestamp]
    }
    
}

