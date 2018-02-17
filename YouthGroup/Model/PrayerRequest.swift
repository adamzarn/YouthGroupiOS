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
    var timestamp: String
    var title: String
    var request: String
    var answered: Bool
    var anonymous: Bool
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.submittedBy = info["submittedBy"] as! String
        self.submittedByEmail = info["submittedByEmail"] as! String
        self.timestamp = info["timestamp"] as! String
        self.title = info["title"] as! String
        self.request = info["request"] as! String
        self.answered = info["answered"] as! Bool
        self.anonymous = info["anonymous"] as! Bool
    }
    
    init(uid: String?, submittedBy: String, submittedByEmail: String, timestamp: String, title: String, request: String, answered: Bool, anonymous: Bool) {
        self.uid = uid
        self.submittedBy = submittedBy
        self.submittedByEmail = submittedByEmail
        self.timestamp = timestamp
        self.title = title
        self.request = request
        self.answered = answered
        self.anonymous = anonymous
    }
    
    func toAnyObject() -> [String: Any] {
        return ["submittedBy": submittedBy,
                "submittedByEmail": submittedByEmail,
                "timestamp": timestamp,
                "title": title,
                "request": request,
                "answered": answered,
                "anonymous": anonymous]
    }

}
