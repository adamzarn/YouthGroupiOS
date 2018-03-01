//
//  AddFreeResponseQuestionViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/24/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class AddFreeResponseQuestionViewController: UIViewController {
    
    @IBOutlet weak var questionTextView: BorderedTextView!
    
    var groupUID: String!
    var lesson: Lesson!
    var frqToEdit: FreeResponseQuestion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selector = #selector(AddMultipleChoiceQuestionViewController.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        questionTextView.inputAccessoryView = toolbar
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let frq = frqToEdit {
            questionTextView.text = frq.question
            title = "Edit Free Response Question"
        } else {
            questionTextView.text = ""
            title = "Add Free Response Question"
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func verifyQuestion() throws {
        let question = questionTextView.text!
        
        if question.isEmpty {
            throw AddFreeResponseQuestionError.missingQuestion
        }
        
        var frq: FreeResponseQuestion!
        if let frqToEdit = frqToEdit {
            frq = FreeResponseQuestion(uid: frq.uid!, position: frqToEdit.position, type: frqToEdit.type, question: question, answerers: frqToEdit.answerers)
        } else {
            let position = (lesson.elements != nil) ? (lesson.elements?.count)! : 0
            frq = FreeResponseQuestion(uid: nil, position: position, type: Elements.freeResponseQuestion.rawValue, question: question, answerers: nil)
        }
        
        FirebaseClient.shared.pushElement(groupUID: groupUID, lessonUID: lesson.uid!, element: frq, completion: { (error, successMessage) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                let completion: (UIAlertAction) -> Void = {_ in
                    self.navigationController?.popViewController(animated: true)
                }
                if let successMessage = successMessage {
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: successMessage, vc: self, completion: completion)
                }
            }
        })
        
    }
    
    @IBAction func submitButtonPressed(sender: Any) {
        do {
            try verifyQuestion()
        } catch AddFreeResponseQuestionError.missingQuestion {
            Alert.showBasic(title: Helper.getString(key: "missingQuestion"), message: Helper.getString(key: "missingQuestionMessage") , vc: self)
        } catch {
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
    }
    
}
