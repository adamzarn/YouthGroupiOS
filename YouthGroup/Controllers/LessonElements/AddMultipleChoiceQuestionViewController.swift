//
//  AddMultipleChoiceQuestionViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class AddMultipleChoiceQuestionViewController: UIViewController {
    
    @IBOutlet weak var questionTextView: BorderedTextView!
    @IBOutlet weak var correctAnswerTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var groupUID: String!
    var lesson: Lesson!
    var mcqToEdit: MultipleChoiceQuestion?
    var incorrectAnswers: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selector = #selector(AddMultipleChoiceQuestionViewController.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        questionTextView.inputAccessoryView = toolbar
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let mcq = mcqToEdit {
            questionTextView.text = mcq.question
            correctAnswerTextField.text = mcq.correctAnswer
            incorrectAnswers = mcq.incorrectAnswers
            title = "Edit Multiple Choice Question"
        } else {
            questionTextView.text = ""
            correctAnswerTextField.text = ""
            title = "Add Multiple Choice Question"
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func addIncorrectAnswerButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Add Incorrect Answer", message: nil, preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if !(field.text?.isEmpty)! {
                    self.incorrectAnswers.append(field.text!)
                    self.tableView.reloadData()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.textAlignment = .center
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func verifyQuestion() throws {
        let question = questionTextView.text!
        let correctAnswer = correctAnswerTextField.text!
        
        if question.isEmpty {
            throw AddMultipleChoiceQuestionError.missingQuestion
        }
        if correctAnswer.isEmpty {
            throw AddMultipleChoiceQuestionError.missingAnswer
        }
        if incorrectAnswers.contains(correctAnswer) {
            throw AddMultipleChoiceQuestionError.invalidIncorrectAnswer
        }
        if incorrectAnswers.count == 0 {
            throw AddMultipleChoiceQuestionError.missingIncorrectAnswers
        }
        
        var mcq: MultipleChoiceQuestion!
        let rand = Int(arc4random_uniform(UInt32(incorrectAnswers.count+1)))
        if let mcqToEdit = mcqToEdit {
            mcq = MultipleChoiceQuestion(uid: mcqToEdit.uid!, position: mcqToEdit.position, type: mcqToEdit.type, correctAnswer: correctAnswer, incorrectAnswers: incorrectAnswers, question: question, correctMembers: mcqToEdit.correctMembers, incorrectMembers: mcqToEdit.incorrectMembers, insert: rand)
        } else {
            let position = (lesson.elements != nil) ? (lesson.elements?.count)! : 0
            mcq = MultipleChoiceQuestion(uid: nil, position: position, type: Elements.multipleChoiceQuestion.rawValue, correctAnswer: correctAnswer, incorrectAnswers: incorrectAnswers, question: question, correctMembers: nil, incorrectMembers: nil, insert: rand)
        }
        
        FirebaseClient.shared.pushElement(groupUID: groupUID, lessonUID: lesson.uid!, element: mcq, completion: { (error, successMessage) in
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
        } catch AddMultipleChoiceQuestionError.missingQuestion {
            Alert.showBasic(title: Helper.getString(key: "missingQuestion"), message: Helper.getString(key: "missingQuestionMessage"), vc: self)
        } catch AddMultipleChoiceQuestionError.missingAnswer {
            Alert.showBasic(title: Helper.getString(key: "missingAnswer"), message: Helper.getString(key: "missingAnswerMessage"), vc: self)
        } catch AddMultipleChoiceQuestionError.invalidIncorrectAnswer {
            Alert.showBasic(title: Helper.getString(key: "invalidIncorrectAnswer"), message: Helper.getString(key: "invalidIncorrectAnswerMessage"), vc: self)
        } catch AddMultipleChoiceQuestionError.missingIncorrectAnswers {
            Alert.showBasic(title: Helper.getString(key: "missingIncorrectAnswers"), message: Helper.getString(key: "missingIncorrectAnswersMessage"), vc: self)
        } catch {
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
    }
    
}

extension AddMultipleChoiceQuestionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension AddMultipleChoiceQuestionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            incorrectAnswers.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Incorrect Answers"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incorrectAnswers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "incorrectAnswerCell")! as UITableViewCell
        cell.textLabel?.text = incorrectAnswers[indexPath.row]
        return cell
    }
    
}
