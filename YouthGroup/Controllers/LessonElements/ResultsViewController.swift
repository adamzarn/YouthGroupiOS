//
//  ResultsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/23/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class ResultsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var questionLabel: UILabel!
    
    var groupUID: String!
    var lessonUID: String!
    var mcq: MultipleChoiceQuestion!
    var answerersArray: [[Answerer]] = []
    var totalAnswers: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 60.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        questionLabel.text = mcq.question
        FirebaseClient.shared.getMultipleChoiceAnswerers(groupUID: groupUID, lessonUID: lessonUID, elementUID: mcq.uid!, completion: { (correctAnswers, incorrectAnswers, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                self.setUpAnswerersArray(correctAnswers: correctAnswers, incorrectAnswers: incorrectAnswers)
            }
        })
    }
    
    func setUpAnswerersArray(correctAnswers: [Answerer]?, incorrectAnswers: [Answerer]?) {
        
        answerersArray = []
        
        if let correctAnswers = correctAnswers {
            answerersArray.append(correctAnswers)
        } else {
            answerersArray.append([Answerer(email: "", name: "No One", leader: false, answer: "", timestamp: 0)])
            totalAnswers = -1
        }
        
        if let incorrectAnswerers = incorrectAnswers {
            let answers = incorrectAnswerers.map { $0.answer } as! [String]
            let uniqueAnswers = Array(Set(answers))
            
            for answer in uniqueAnswers {
                var tempArray: [Answerer] = []
                for answerer in incorrectAnswerers {
                    if answerer.answer == answer {
                        tempArray.append(answerer)
                    }
                }
                answerersArray.append(tempArray)
            }
        }
        
        totalAnswers = totalAnswers + answerersArray.map { $0.count }.reduce(0, +)
        tableView.reloadData()
        
    }
    
}

extension ResultsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        
        let percentage = Double(answerersArray[section].count) / Double(totalAnswers) * 100
        let roundedPercentage = Double(round(10*percentage)/10)
        if answerersArray[section][0].email.isEmpty {
            return "(Correct) (0.0%) \(mcq.correctAnswer!)"
        }
        if section == 0 {
            return "(Correct) (\(roundedPercentage)%) \(mcq.correctAnswer!)"
        }
        if answerersArray[section].count > 0 {
            return "(\(roundedPercentage)%) \(answerersArray[section][0].answer!)"
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return answerersArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return answerersArray[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell") as! MemberCell
        cell.setUp(member: answerersArray[indexPath.section][indexPath.row])
        return cell
    }
    
}
