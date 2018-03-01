//
//  LessonElements.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

enum Elements: Int {
    case activity = 0
    case passage = 1
    case multipleChoiceQuestion = 2
    case freeResponseQuestion = 3
}

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
        self.elements = Helper.convertAnyObjectToLessonElements(dict: info["elements"] as? [String:[String: Any]])
    }
    
    func toAnyObject() -> [String: Any] {
        return ["title": title,
                "date": date,
                "locked": locked,
                "leaders": Helper.convertMembersToAnyObject(members: leaders),
                "elements": Helper.convertLessonElementsToAnyObject(elements: elements)]
    }
    
}

class LessonElement {
    var uid: String?
    var position: Int!
    var type: Int!
}

class Activity: LessonElement {
    var name: String!
    var directions: String!
    init(uid: String?, position: Int, type: Int, name: String, directions: String) {
        super.init()
        super.uid = uid
        super.position = position
        super.type = type
        self.name = name
        self.directions = directions
    }
    
    init(uid: String, info: [String:Any]) {
        super.init()
        self.uid = uid
        self.position = info["position"] as! Int
        self.type = info["type"] as! Int
        self.name = info["name"] as! String
        self.directions = info["directions"] as! String
    }
    
    func toAnyObject() -> [String: Any] {
        return ["position": position,
                "type": type,
                "name": name,
                "directions": directions]
    }
    
}

class Passage: LessonElement {
    var reference: String!
    var text: String!
    init(uid: String?, position: Int, type: Int, reference: String, text: String) {
        super.init()
        super.uid = uid
        super.position = position
        super.type = type
        self.reference = reference
        self.text = text
    }
    
    init(uid: String, info: [String:Any]) {
        super.init()
        self.uid = uid
        self.position = info["position"] as! Int
        self.type = info["type"] as! Int
        self.reference = info["reference"] as! String
        self.text = info["text"] as! String
    }
    
    func toAnyObject() -> [String: Any] {
        return ["position": position,
                "type": type,
                "reference": reference,
                "text": text]
    }
    
}

class MultipleChoiceQuestion: LessonElement {
    var correctAnswer: String!
    var incorrectAnswers: [String]!
    var question: String!
    var correctMembers: [Answerer]?
    var incorrectMembers: [Answerer]?
    var insert: Int!
    init(uid: String?, position: Int, type: Int, correctAnswer: String, incorrectAnswers: [String], question: String, correctMembers: [Answerer]?, incorrectMembers: [Answerer]?, insert: Int) {
        super.init()
        super.uid = uid
        super.position = position
        super.type = type
        self.correctAnswer = correctAnswer
        self.incorrectAnswers = incorrectAnswers
        self.question = question
        self.correctMembers = correctMembers
        self.incorrectMembers = incorrectMembers
        self.insert = insert
    }
    
    init(uid: String, info: [String:Any]) {
        super.init()
        self.uid = uid
        self.position = info["position"] as! Int
        self.type = info["type"] as! Int
        self.correctAnswer = info["correctAnswer"] as! String
        self.question = info["question"] as! String
        self.incorrectAnswers = Helper.convertAnyObjectToStringArray(dict: info["incorrectAnswers"] as! [String: Bool])
        if let correctMembers = info["correctMembers"] {
            self.correctMembers = Helper.convertAnyObjectToAnswerers(dict: correctMembers as! [String:[String : Any]], leader: false)
        }
        if let incorrectMembers = info["incorrectMembers"] {
            self.incorrectMembers = Helper.convertAnyObjectToAnswerers(dict: incorrectMembers as! [String:[String : Any]], leader: false)
        }
        self.insert = info["insert"] as! Int
    }
    
    func toAnyObject() -> [String: Any] {
        return ["position": position,
                "type": type,
                "correctAnswer": correctAnswer,
                "question": question,
                "incorrectAnswers": Helper.convertIncorrectAnswersToAnyObject(incorrectAnswers: incorrectAnswers),
                "correctMembers": Helper.convertAnswerersToAnyObject(answerers: correctMembers),
                "incorrectMembers": Helper.convertAnswerersToAnyObject(answerers: incorrectMembers),
                "insert": insert]
    }
    
}

class FreeResponseQuestion: LessonElement {
    var question: String!
    var answerers: [Answerer]?
    init(uid: String?, position: Int, type: Int, question: String, answerers: [Answerer]?) {
        super.init()
        super.uid = uid
        super.position = position
        super.type = type
        self.question = question
        self.answerers = answerers
    }
    
    init(uid: String, info: [String:Any]) {
        super.init()
        self.uid = uid
        self.position = info["position"] as! Int
        self.type = info["type"] as! Int
        self.question = info["question"] as! String
        if let answerers = info["answerers"] {
            self.answerers = Helper.convertAnyObjectToAnswerers(dict: answerers as! [String:[String : Any]], leader: false)
        }
    }
    
    func toAnyObject() -> [String: Any] {
        return ["position": position,
                "type": type,
                "question": question,
                "answerers": Helper.convertAnswerersToAnyObject(answerers: answerers)]
    }
    
}
