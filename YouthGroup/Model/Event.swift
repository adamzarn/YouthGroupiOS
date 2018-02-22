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
    var going: [Bringer]?
    var maybe: [Bringer]?
    var notGoing: [Bringer]?
    
    init(uid: String?, name: String, date: String, startTime: String, endTime: String, locationName: String, address: Address, notes: String?, going: [Bringer]?, maybe: [Bringer]?, notGoing: [Bringer]?) {
        self.uid = uid
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.locationName = locationName
        self.address = address
        self.notes = notes
        self.going = going
        self.maybe = maybe
        self.notGoing = notGoing
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
        if let going = info["going"] {
            self.going = Helper.convertAnyObjectToBringers(dict: going as! [String:[String : String]], leader: false)
        }
        if let maybe = info["maybe"] {
            self.maybe = Helper.convertAnyObjectToBringers(dict: maybe as! [String:[String : String]], leader: false)
        }
        if let notGoing = info["notGoing"] {
            self.notGoing = Helper.convertAnyObjectToBringers(dict: notGoing as! [String:[String : String]], leader: false)
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
                "going": Helper.convertBringersToAnyObject(bringers: self.going),
                "maybe": Helper.convertBringersToAnyObject(bringers: self.maybe),
                "notGoing": Helper.convertBringersToAnyObject(bringers: self.notGoing)]
    }
    
}

struct Address {
    var street: String
    var city: String
    var state: String
    var zip: String
}
