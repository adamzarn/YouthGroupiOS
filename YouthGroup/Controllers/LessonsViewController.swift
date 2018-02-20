//
//  LessonsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class LessonsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let verse = "Matthew 1:16-25"
        if let parameters = verse.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            NetworkClient.shared.getBibleVerses(parameters: parameters, completion: { (reference, text, verses) in
                if let reference = reference, let text = text, let verses = verses {
//                    print(reference)
//                    print(text)
//                    for verse in verses {
//                        print("\(verse.number) \(verse.text)")
//                    }
                }
            })
        }
        
        let passage1 = Passage(uid: nil, position: 0, reference: "hello")
        let passage2 = Passage(uid: nil, position: 2, reference: "goodbye")
        let question1 = MultipleChoiceQuestion(uid: nil, position: 1, correctAnswer: "yes", incorrectAnswers: [], question: "", correctMembers: nil, incorrectMembers: nil)
        let question2 = MultipleChoiceQuestion(uid: nil, position: 3, correctAnswer: "no", incorrectAnswers: [], question: "", correctMembers: nil, incorrectMembers: nil)
        
        let lessonElements: [LessonElement] = [passage1, passage2, question1, question2]
        let sorted = lessonElements.sorted(by: { $0.position < $1.position })
        for element in sorted {
            if element is Passage {
                print((element as! Passage).reference)
            }
            if element is MultipleChoiceQuestion {
                print((element as! MultipleChoiceQuestion).correctAnswer)
            }
        }
        
        let lesson = Lesson(uid: nil, name: "New Lesson", date: "2/20/2018", locked: false, leaders: [Member(email: "aa", name: "aa", leader: false)], elements: sorted)
    }
    
}
