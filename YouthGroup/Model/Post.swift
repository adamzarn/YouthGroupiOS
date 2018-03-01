//
//  Post.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/26/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class Post {
    
    var uid: String?
    var email: String!
    var name: String!
    var timestamp: Int64!
    var text: String!
    
    init(uid: String?, email: String, name: String, timestamp: Int64, text: String) {
        self.uid = uid
        self.email = email
        self.name = name
        self.timestamp = timestamp
        self.text = text
    }
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.email = info["email"] as! String
        self.name = info["name"] as! String
        self.timestamp = info["timestamp"] as! Int64
        self.text = info["text"] as! String
    }
    
    func toAnyObject() -> [String: Any] {
        return ["email": self.email,
                "name": self.name,
                "timestamp": self.timestamp,
                "text": self.text]
    }
    
}
