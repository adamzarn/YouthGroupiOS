//
//  AnswersViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/24/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class AnswersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var questionLabel: UILabel!
    
    var groupUID: String!
    var lesson: Lesson!
    var frq: FreeResponseQuestion!
    var answerers: [Answerer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: px)
        let line = UIView(frame: frame)
        tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        questionLabel.text = frq.question
        
        FirebaseClient.shared.getFreeResponseAnswerers(groupUID: groupUID, lessonUID: lesson.uid!, elementUID: frq.uid!, completion: { (answerers, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let answerers = answerers {
                    self.answerers = answerers.sorted { $0.timestamp < $1.timestamp }
                    self.tableView.reloadData()
                }
            }
        })
        
    }
    
}

extension AnswersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let answerer = self.answerers[indexPath.row]
        if let email = Auth.auth().currentUser?.email {
            let isLeader = lesson.leaders.filter { $0.email == email }
            if isLeader != nil && answerer.email == email {
                return true
            }
            return false
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let email = frq.answerers![indexPath.row].email!
            FirebaseClient.shared.deleteFreeResponseAnswer(groupUID: groupUID, lessonUID: lesson.uid!, elementUID: frq.uid!, email: email, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.answerers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell") as! AnswerCell
        cell.setUp(answerer: self.answerers[indexPath.row])
        return cell
    }
    
}

