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
    var name: String!
    var date: String!
    var locked: Bool!
    var leaders: [Member]!
    var elements: [LessonElement]?
    init(uid: String?, name: String, date: String, locked: Bool, leaders: [Member], elements: [LessonElement]?) {
        self.uid = uid
        self.name = name
        self.date = date
        self.locked = locked
        self.leaders = leaders
        self.elements = elements
    }
}

class LessonElement {
    var uid: String?
    var position: Int!
}

class Passage: LessonElement {
    var reference: String!
    init(uid: String?, position: Int, reference: String) {
        super.init()
        super.uid = uid
        super.position = position
        self.reference = reference
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

