//
//  LessonViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class LessonViewController: UIViewController {
    
    var lesson: Lesson!
    var groupUID: String!
    var isLeader = false
    var elements: [LessonElement] = []
    var passages: [Passage] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addElementButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let passage1 = Passage(uid: nil, position: 0, reference: "John 3:16", text: "")
        let passage2 = Passage(uid: nil, position: 1, reference: "Matthew 1:1", text: "")
        let passage3 = Passage(uid: nil, position: 2, reference: "John 8:58", text: "")
        elements = [passage1, passage2, passage3]
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 140.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = lesson.title
        setUpAddElementButton(isLeader: isLeader)
        getVerses()
    }
    
    func getVerses() {
        
        for passage in elements {
            if let parameters = (passage as! Passage).reference.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                NetworkClient.shared.getBibleVerses(parameters: parameters, completion: { (reference, text, verses) in
                    if let reference = reference, let text = text {
                        let trimmedText = text.replacingOccurrences(of: "\n", with: "")
                        let passage = Passage(uid: nil, position: 0, reference: reference, text: trimmedText)
                        self.passages.append(passage)
                        if self.passages.count == self.elements.count {
                            DispatchQueue.main.async {
                                self.passages.sort(by: { $0.position < $1.position })
                                self.tableView.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func addElementButtonPressed(sender: Any) {
        let actionSheet = UIAlertController(title: "Add Lesson Element", message: nil, preferredStyle: .actionSheet)
        
        let activity = UIAlertAction(title: "Activity", style: .default, handler: { (UIAlertAction) -> Void in
            print("activity")
        })
        let passage = UIAlertAction(title: "Bible Passage", style: .default, handler: { (UIAlertAction) -> Void in
            print("passage")
        })
        let multipleChoiceQuestion = UIAlertAction(title: "Multiple Choice Question", style: .default, handler: { (UIAlertAction) -> Void in
            print("multiple choice question")
        })
        let freeResponseQuestion = UIAlertAction(title: "Free Response Question", style: .default, handler: { (UIAlertAction) -> Void in
            print("free response question")
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) -> Void in
            print("cancel")
        })
        
        actionSheet.addAction(activity)
        actionSheet.addAction(passage)
        actionSheet.addAction(multipleChoiceQuestion)
        actionSheet.addAction(freeResponseQuestion)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true, completion: nil)

    }
    
    @IBAction func dismissButtonPressed(sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func setUpAddElementButton(isLeader: Bool) {
        if isLeader {
            addElementButton.isEnabled = true
            addElementButton.tintColor = nil
        } else {
            addElementButton.isEnabled = false
            addElementButton.tintColor = .clear
        }
    }
    
}

extension LessonViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let passage = passages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "biblePassageCell") as! BiblePassageCell
        cell.setUp(passage: passage)
        return cell
    }
    
}
