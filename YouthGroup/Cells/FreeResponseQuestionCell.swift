//
//  FreeResponseQuestionCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

protocol FreeResponseQuestionCellDelegate: class {
    func didSumbitAnswer(error: String?)
}

class FreeResponseQuestionCell: UITableViewCell {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTextView: BorderedTextView!
    @IBOutlet weak var submitButton: YouthGroupButton!
    @IBOutlet weak var backgroundCardView: UIView!
    
    var groupUID: String!
    var lessonUID: String!
    var elementUID: String!
    
    weak var delegate: FreeResponseQuestionCellDelegate?
    
    override func awakeFromNib() {
        let selector = #selector(FreeResponseQuestionCell.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        answerTextView.inputAccessoryView = toolbar
        answerTextView.backgroundColor = Colors.darkGray.withAlphaComponent(0.5)
        submitButton.backgroundColor = Colors.darkGray
        submitButton.layer.borderColor = UIColor.white.cgColor
        submitButton.layer.borderWidth = 0.5
        submitButton.isEnabled = true
    }
    
    func setUp(frq: FreeResponseQuestion, groupUID: String, lessonUID: String, editing: Bool) {
        
        self.groupUID = groupUID
        self.lessonUID = lessonUID
        self.elementUID = frq.uid!
        
        questionLabel.text = frq.question
        backgroundCardView.makeCardView()
        backgroundCardView.backgroundColor = Colors.darkGray
        
        if editing {
            
            answerTextView.isHidden = true
            submitButton.isHidden = true
            questionLabel.numberOfLines = 1
            questionLabel.minimumScaleFactor = 1.0
            
        } else {
            
            answerTextView.isHidden = false
            submitButton.isHidden = false
            questionLabel.numberOfLines = 0
            questionLabel.minimumScaleFactor = 0.5
            
            if let currentAnswerer = Helper.getCurrentAnswerer(correctMembers: frq.answerers, incorrectMembers: nil) {
                answerTextView.text = currentAnswerer.answer
                submitButton.setTitle("RESUBMIT", for: .normal)
            } else {
                answerTextView.text = ""
                submitButton.setTitle("SUBMIT", for: .normal)
            }
        }
        
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        if !answerTextView.text.isEmpty {
            if let member = Helper.createMemberFromUser(), let email = member.email {
                let answerer = Answerer(email: email, name: member.name, leader: false, answer: answerTextView.text!, timestamp: -1*Int64(Helper.getCurrentDateAndTime())!)
                FirebaseClient.shared.answerFreeResponseQuestion(groupUID: groupUID, lessonUID: lessonUID, elementUID: elementUID, answerer: answerer, completion: { (error) in
                    if let error = error {
                        self.delegate?.didSumbitAnswer(error: error)
                    } else {
                        self.delegate?.didSumbitAnswer(error: nil)
                    }
                })
            }
        }
    }
    
}
