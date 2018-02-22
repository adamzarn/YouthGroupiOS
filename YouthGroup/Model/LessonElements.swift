//
//  LessonElements.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

class Lesson {
    var uid: String?
    var title: String!
    var date: String!
    var locked: Bool!
    var leaders: [Member]!
    var elements: [LessonElement]?
    init(uid: String?, title: String, date: String, locked: Bool, leaders: [Member], elements: [LessonElement]?) {
        self.uid = uid
        self.title = title
        self.date = date
        self.locked = locked
        self.leaders = leaders
        self.elements = elements
    }
    
    init(uid: String, info: NSDictionary) {
        self.uid = uid
        self.title = info["title"] as! String
        self.date = info["date"] as! String
        self.locked = info["locked"] as! Bool
        self.leaders = Helper.convertAnyObjectToMembers(dict: info["leaders"] as! [String:[String : String]], leader: true)
        //if let elements = info["elements"] {
            //self.students = Helper.convertAnyObjectToLessonElements(dict: students as! [String: [String : String]], leader: false)
        //}
    }
    
    func toAnyObject() -> [String: Any] {
        return ["title": title,
                "date": date,
                "locked": locked,
                "leaders": Helper.convertMembersToAnyObject(members: leaders),
                "elements": ""]
    }
    
}

class LessonElement {
    var uid: String?
    var position: Int!
}

class Passage: LessonElement {
    var reference: String!
    var text: String!
    init(uid: String?, position: Int, reference: String, text: String) {
        super.init()
        super.uid = uid
        super.position = position
        self.reference = reference
        self.text = text
    }
}

class MultipleChoiceQuestion: LessonElement {
    var correctAnswer: String!
    var incorrectAnswers: [String]!
    var question: String!
    var correctMembers: [Member]?
    var incorrectMembers: [Member]?
    init(uid: String?, position: Int, correctAnswer: String, incorrectAnswers: [String], question: String, correctMembers: [Member]?, incorrectMembers: [Member]?) {
        super.init()
        super.uid = uid
        super.position = position
        self.correctAnswer = correctAnswer
        self.incorrectAnswers = incorrectAnswers
        self.question = question
        self.correctMembers = correctMembers
        self.incorrectMembers = incorrectMembers
    }
}

class FreeResponseQuestion: LessonElement {
    var question: String!
    var responses: [Response]?
    init(uid: String?, position: Int, question: String, responses: [Response]?) {
        super.init()
        super.uid = uid
        super.position = position
        self.question = question
        self.responses = responses
    }
}

struct Response {
    var email: String!
    var name: String!
    var response: String!
}

class Activity: LessonElement {
    var name: String!
    var directions: String!
    init(uid: String?, position: Int, name: String, directions: String) {
        super.init()
        super.uid = uid
        super.position = position
        self.name = name
        self.directions = directions
    }
}

