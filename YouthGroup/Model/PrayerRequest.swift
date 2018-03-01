//
//  PrayerRequest.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

struct PrayerRequest {
    
    var uid: String?
    var submittedBy: String
    var submittedByEmail: String
    var timestamp: Int64
    var title: String
    var request: String
    var answered: Bool
    var anonymous: Bool
    var prayingMembers: [Member]?
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.submittedBy = info["submittedBy"] as! String
        self.submittedByEmail = info["submittedByEmail"] as! String
        self.timestamp = info["timestamp"] as! Int64
        self.title = info["title"] as! String
        self.request = info["request"] as! String
        self.answered = info["answered"] as! Bool
        self.anonymous = info["anonymous"] as! Bool
        if let prayingMembers = info["prayingMembers"] {
            self.prayingMembers = Helper.convertAnyObjectToMembers(dict: prayingMembers as! [String:[String : String]], leader: false)
        }
    }
    
    init(uid: String?, submittedBy: String, submittedByEmail: String, timestamp: Int64, title: String, request: String, answered: Bool, anonymous: Bool, prayingMembers: [Member]?) {
        self.uid = uid
        self.submittedBy = submittedBy
        self.submittedByEmail = submittedByEmail
        self.timestamp = timestamp
        self.title = title
        self.request = request
        self.answered = answered
        self.anonymous = anonymous
        self.prayingMembers = prayingMembers
    }
    
    func toAnyObject() -> [String: Any] {
        return ["submittedBy": submittedBy,
                "submittedByEmail": submittedByEmail,
                "timestamp": timestamp,
                "title": title,
                "request": request,
                "answered": answered,
                "anonymous": anonymous,
                "prayingMembers": Helper.convertMembersToAnyObject(members: prayingMembers)]
    }

}
