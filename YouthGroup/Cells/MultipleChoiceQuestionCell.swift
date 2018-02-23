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
    
    func setUp(mcq: MultipleChoiceQuestion, groupUID: String, lessonUID: String) {
        
        self.groupUID = groupUID
        self.lessonUID = lessonUID
        self.elementUID = mcq.uid!
        
        for view in self.subviews {
            if view is UIStackView {
                view.removeFromSuperview()
            }
        }
        
        self.mcq = mcq
        questionLabel.text = mcq.question
        choices = mcq.incorrectAnswers!
        choices.insert(mcq.correctAnswer, at: mcq.insert)
            
        let y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 20.0
            
        for i in 1...choices.count {
            let stackView = makeAnswer(text: choices[i-1], tag: i)
            stackView.frame.origin.x = 20.0
            stackView.frame.origin.y = y + CGFloat(i-1)*40.0
            stackView.frame.size.width = self.frame.size.width - 40.0
            stackView.frame.size.height = 30.0
            self.addSubview(stackView)
        }
            
        backgroundCardView.makeCardView()
        backgroundCardView.backgroundColor = Colors.lightGray
        
        if let currentAnswerer = getCurrentAnswerer() {
            check(answer: currentAnswerer.answer!, correctAnswer: mcq.correctAnswer)
        }
        
    }
    
    func getCurrentAnswerer() -> Answerer? {
        var answerers: [Answerer] = []
        if let incorrectMembers = mcq.incorrectMembers {
            answerers += incorrectMembers
        }
        if let correctMembers = mcq.correctMembers {
            answerers += correctMembers
        }
        if let email = Auth.auth().currentUser?.email {
            let currentAnswerers = answerers.filter({ $0.email == email })
            if currentAnswerers.count > 0 {
                return currentAnswerers[0]
            } else {
                return nil
            }
        }
        return nil
    }
    
    func check(answer: String, correctAnswer: String) {
        let tag = choices.index(of: answer)! + 1
        let correctTag = choices.index(of: correctAnswer)! + 1
        
        let buttonToCheck = self.viewWithTag(tag) as! UIButton
        buttonToCheck.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        
        let labelToChange = self.viewWithTag(-tag) as! UILabel
        if answer == correctAnswer {
            labelToChange.text = "\(labelToChange.text!) (CORRECT)"
        } else {
            labelToChange.text = "\(labelToChange.text!) (INCORRECT)"
            let correctAnswerLabel = self.viewWithTag(-correctTag) as! UILabel
            correctAnswerLabel.text = "\(correctAnswerLabel.text!) (CORRECT)"
        }
    }
    
    func makeAnswer(text: String, tag: Int) -> UIStackView {
        
        //Button
        let button = CheckboxButton(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0))
        button.addTarget(self, action: #selector(MultipleChoiceQuestionCell.selectAnswer(sender:)), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        button.tag = tag
        
        //Text Label
        let answerLabel = UILabel()
        answerLabel.text = text
        answerLabel.textColor = .white
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

        if getCurrentAnswerer() == nil {
            sender.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
            let tag = sender.tag
            let answer = choices[tag-1]
            let correct = (answer == mcq.correctAnswer)
            FirebaseClient.shared.answerMultipleChoiceQuestion(groupUID: groupUID, lessonUID: lessonUID, elementUID: elementUID, correct: correct, answer: answer, completion: { (error) in
                if let error = error {
                    print("error")
                }
            })
        }
    }
    
}
