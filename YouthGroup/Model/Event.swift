//
//  Event.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import Firebase

class Event {
    
    var uid: String?
    var name: String
    var date: String
    var startTime: String
    var endTime: String
    var locationName: String
    var address: Address
    var notes: String?
    var attending: [Member]?
    var maybe: [Member]?
    var notAttending: [Member]?
    
    init(uid: String?, name: String, date: String, startTime: String, endTime: String, locationName: String, address: Address, notes: String?, attending: [Member]?, maybe: [Member]?, notAttending: [Member]?) {
        self.uid = uid
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.locationName = locationName
        self.address = address
        self.notes = notes
        self.attending = attending
        self.maybe = maybe
        self.notAttending = notAttending
    }
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.name = info["name"] as! String
        self.date = info["date"] as! String
        self.startTime = info["startTime"] as! String
        self.endTime = info["endTime"] as! String
        self.locationName = info["locationName"] as! String
        self.address = Helper.convertAnyObjectToAddress(dict: info["address"] as! NSDictionary)
        if let notes = info["notes"] {
            self.notes = notes as? String
        }
        if let attending = info["attending"] {
            self.attending = Helper.convertAnyObjectToMembers(dict: attending as! [String : String], leader: false)
        }
        if let maybe = info["maybe"] {
            self.maybe = Helper.convertAnyObjectToMembers(dict: maybe as! [String : String], leader: false)
        }
        if let notAttending = info["notAttending"] {
            self.notAttending = Helper.convertAnyObjectToMembers(dict: notAttending as! [String : String], leader: false)
        }
    }
    
    func toAnyObject() -> [String: Any] {
        return ["name": self.name,
                "date": self.date,
                "startTime": self.startTime,
                "endTime": self.endTime,
                "locationName": self.locationName,
                "address": Helper.convertAddressToAnyObject(address: self.address),
                "notes": self.notes,
                "attending": Helper.convertMembersToAnyObject(members: self.attending),
                "maybe": Helper.convertMembersToAnyObject(members: self.maybe),
                "notAttending": Helper.convertMembersToAnyObject(members: self.notAttending)]
    }
    
}

struct Address {
    var street: String
    var city: String
    var state: String
    var zip: String
}
