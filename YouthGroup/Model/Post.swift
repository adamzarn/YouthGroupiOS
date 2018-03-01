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
    var comments: [Post]?
    
    init(uid: String?, email: String, name: String, timestamp: Int64, text: String, comments: [Post]?) {
        self.uid = uid
        self.email = email
        self.name = name
        self.timestamp = timestamp
        self.text = text
        self.comments = comments
    }
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.email = info["email"] as! String
        self.name = info["name"] as! String
        self.timestamp = info["timestamp"] as! Int64
        self.text = info["text"] as! String
        if let comments = info["comments"] {
            self.comments = Helper.convertAnyObjectToPosts(dict: comments as! [String:[String : Any]])
        }
    }
    
    func toAnyObject() -> [String: Any] {
        return ["email": self.email,
                "name": self.name,
                "timestamp": self.timestamp,
                "text": self.text,
                "comments": Helper.convertPostsToAnyObject(posts: self.comments)]
    }
    
}
