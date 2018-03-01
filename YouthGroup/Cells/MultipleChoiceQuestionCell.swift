//
//  MultipleChoiceQuestionCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class MultipleChoiceQuestionCell: UITableViewCell {

    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var backgroundCardView: UIView!
    var mcq: MultipleChoiceQuestion!
    var choices: [String]!
    
    var groupUID: String!
    var lessonUID: String!
    var elementUID: String!
    
    func getQuestionLabelHeight(question: String) -> CGFloat {
        let width = self.contentView.frame.size.width - 32.0
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = question
        label.sizeToFit()
        return label.frame.height
    }
    
    func setUp(mcq: MultipleChoiceQuestion, groupUID: String, lessonUID: String, editing: Bool) {
        
        self.groupUID = groupUID
        self.lessonUID = lessonUID
        self.elementUID = mcq.uid!
        
        self.mcq = mcq
        questionLabel.text = mcq.question
        choices = mcq.incorrectAnswers!
        choices.insert(mcq.correctAnswer, at: mcq.insert)
            
        let y = questionLabel.frame.origin.y + getQuestionLabelHeight(question: mcq.question) + 20.0
        
        while subviews.count > 2 {
            self.subviews.last?.removeFromSuperview()
        }
        
        backgroundCardView.makeCardView()
        backgroundCardView.backgroundColor = Colors.lightGray
        
        if editing {
            
            questionLabel.numberOfLines = 1
            questionLabel.minimumScaleFactor = 1.0
            
        } else {
            
            questionLabel.numberOfLines = 0
            questionLabel.minimumScaleFactor = 0.5
        
            for i in 1...choices.count {
                let stackView = makeAnswer(text: choices[i-1], tag: i)
                stackView.frame.origin.x = 20.0
                stackView.frame.origin.y = y + CGFloat(i-1)*40.0
                stackView.frame.size.width = self.frame.size.width - 40.0
                stackView.frame.size.height = 30.0
                self.addSubview(stackView)
            }
            
            if let currentAnswerer = Helper.getCurrentAnswerer(correctMembers: mcq.correctMembers, incorrectMembers: mcq.incorrectMembers) {
                check(answer: currentAnswerer.answer!, correctAnswer: mcq.correctAnswer)
            }
            
        }
        
    }
    
    func check(answer: String, correctAnswer: String) {
        let tag = choices.index(of: answer)! + 1
        let correctTag = choices.index(of: correctAnswer)! + 1
        
        let buttonToCheck = self.viewWithTag(tag)
        
        if buttonToCheck is UIImageView {
            buttonToCheck?.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
            (buttonToCheck as! UIImageView).image = #imageLiteral(resourceName: "checkmark")
        }
        if buttonToCheck is CheckboxButton {
            buttonToCheck?.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
            (buttonToCheck as! CheckboxButton).setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        }
        
        let labelToChange = self.viewWithTag(-tag) as! UILabel
        if answer == correctAnswer {
            labelToChange.text = "(CORRECT) \(choices[correctTag-1])"
        } else {
            labelToChange.text = "(INCORRECT) \(choices[tag-1])"
            let correctAnswerLabel = self.viewWithTag(-correctTag) as! UILabel
            correctAnswerLabel.text = "(CORRECT) \(choices[correctTag-1])"
        }
    }
    
    func makeAnswer(text: String, tag: Int) -> UIStackView {
        
        //Button
        let button = CheckboxButton(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0))
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(MultipleChoiceQuestionCell.selectAnswer(sender:)), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        button.tag = tag
        
        //Text Label
        let answerLabel = UILabel()
        answerLabel.text = text
        answerLabel.textColor = .white
        answerLabel.numberOfLines = 0
        answerLabel.adjustsFontSizeToFitWidth = true
        answerLabel.minimumScaleFactor = 0.5
        answerLabel.widthAnchor.constraint(equalToConstant: self.contentView.frame.width).isActive = true
        answerLabel.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        answerLabel.textAlignment = .left
        answerLabel.tag = -tag
        
        //Stack View
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = UIStackViewDistribution.equalSpacing
        stackView.alignment = UIStackViewAlignment.center
        stackView.spacing = 16.0
        
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(answerLabel)
        
        return stackView
        
    }
    
    @objc func selectAnswer(sender: UIButton) {

        if Helper.getCurrentAnswerer(correctMembers: mcq.correctMembers, incorrectMembers: mcq.incorrectMembers) == nil {
            sender.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
            let tag = sender.tag
            let answer = choices[tag-1]
            let correct = (answer == mcq.correctAnswer)
            if let member = Helper.createMemberFromUser(), let email = member.email {
                let answerer = Answerer(email: email, name: member.name, leader: false, answer: answer, timestamp: -1*Int64(Helper.getCurrentDateAndTime())!)
                FirebaseClient.shared.answerMultipleChoiceQuestion(groupUID: groupUID, lessonUID: lessonUID, elementUID: elementUID, correct: correct, answerer: answerer, completion: { (error) in
                    if let error = error {
                        print("error")
                    }
                })
            }
        }
    }
    
}
