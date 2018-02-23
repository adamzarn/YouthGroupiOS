//
//  LessonViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class LessonViewController: UIViewController {
    
    var lesson: Lesson!
    var groupUID: String!
    var isLeader = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addElementButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 140.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = lesson.title
        setUpBarButtonItems(isLeader: isLeader)
        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.isLeader(groupUID: groupUID, email: email, completion: { (isLeader, error) in
                self.isLeader = isLeader
                self.setUpBarButtonItems(isLeader: isLeader)
                self.getElements()
            })
        }
    }
    
    func getElements() {
        FirebaseClient.shared.getElements(groupUID: groupUID, lessonUID: lesson.uid!, completion: { (elements, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let elements = elements {
                    self.lesson.elements = elements
                    self.lesson.elements?.sort(by: { $0.position < $1.position })
                    self.tableView.reloadData()
                }
            }
        })
    }

    @IBAction func addElementButtonPressed(sender: Any) {
        let actionSheet = UIAlertController(title: "Add Lesson Element", message: nil, preferredStyle: .actionSheet)
        
        let activity = UIAlertAction(title: "Activity", style: .default, handler: { (UIAlertAction) -> Void in
            let addActivityVC = self.storyboard?.instantiateViewController(withIdentifier: "AddActivityViewController") as! AddActivityViewController
            addActivityVC.groupUID = self.groupUID
            addActivityVC.lesson = self.lesson
            self.navigationController?.pushViewController(addActivityVC, animated: true)
        })
        let passage = UIAlertAction(title: "Bible Passage", style: .default, handler: { (UIAlertAction) -> Void in
            let addPassageVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPassageViewController") as! AddPassageViewController
            addPassageVC.groupUID = self.groupUID
            addPassageVC.lesson = self.lesson
            self.navigationController?.pushViewController(addPassageVC, animated: true)
        })
        let multipleChoiceQuestion = UIAlertAction(title: "Multiple Choice Question", style: .default, handler: { (UIAlertAction) -> Void in
            let addMultipleChoiceQuestionVC = self.storyboard?.instantiateViewController(withIdentifier: "AddMultipleChoiceQuestionViewController") as! AddMultipleChoiceQuestionViewController
            addMultipleChoiceQuestionVC.groupUID = self.groupUID
            addMultipleChoiceQuestionVC.lesson = self.lesson
            self.navigationController?.pushViewController(addMultipleChoiceQuestionVC, animated: true)
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
    
    func setUpBarButtonItems(isLeader: Bool) {
        if isLeader {
            addElementButton.isEnabled = true
            addElementButton.tintColor = nil
            editButton.isEnabled = true
            editButton.tintColor = nil
        } else {
            addElementButton.isEnabled = false
            addElementButton.tintColor = .clear
            editButton.isEnabled = false
            editButton.tintColor = .clear
        }
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if editButton.style == .plain {
            editButton.title = "Done"
            editButton.style = .done
            tableView.isEditing = true
        } else {
            editButton.title = "Edit"
            editButton.style = .plain
            tableView.isEditing = false
        }
    }
    
    
}

extension LessonViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if lesson.elements![indexPath.row] is MultipleChoiceQuestion {
            let mcq = lesson.elements![indexPath.row] as! MultipleChoiceQuestion
            let count = mcq.incorrectAnswers.count + 1
            return 104.0 + CGFloat(count)*40
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return tableView.isEditing ? UITableViewCellEditingStyle.none : UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if isLeader { return true }; return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let elementToMove = lesson.elements![sourceIndexPath.row]
        lesson.elements!.remove(at: sourceIndexPath.row)
        lesson.elements!.insert(elementToMove, at: destinationIndexPath.row)
        let elementUIDs = lesson.elements!.map { $0.uid! }
        var i = 0
        for elementUID in elementUIDs {
            FirebaseClient.shared.setPosition(groupUID: groupUID, lessonUID: lesson.uid!, elementUID: elementUID, position: i, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                }
            })
            i+=1
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if isLeader { return true }; return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let elementUID = lesson.elements![indexPath.row].uid!
            FirebaseClient.shared.deleteElement(groupUID: groupUID, lessonUID: lesson.uid!, elementUID: elementUID, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lesson.elements?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = lesson.elements![indexPath.row]
        switch element.type {
        case Elements.activity.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell") as! ActivityCell
            cell.setUp(activity: element as! Activity)
            return cell
        case Elements.passage.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "biblePassageCell") as! BiblePassageCell
            cell.setUp(passage: element as! Passage, groupUID: groupUID)
            return cell
        case Elements.multipleChoiceQuestion.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "multipleChoiceQuestionCell") as! MultipleChoiceQuestionCell
            cell.shouldIndentWhileEditing = false
            cell.setUp(mcq: element as! MultipleChoiceQuestion, groupUID: groupUID, lessonUID: lesson.uid!)
            return cell
        case Elements.freeResponseQuestion.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "freeResponseQuestionCell") as! FreeResponseQuestionCell
            cell.setUp(freeResponseQuestion: element as! FreeResponseQuestion)
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let element = lesson.elements![indexPath.row]
        if isLeader {
            if element is Activity {
                let addActivityVC = self.storyboard?.instantiateViewController(withIdentifier: "AddActivityViewController") as! AddActivityViewController
                addActivityVC.groupUID = self.groupUID
                addActivityVC.lesson = self.lesson
                addActivityVC.activityToEdit = (element as! Activity)
                self.navigationController?.pushViewController(addActivityVC, animated: true)
            }
            if element is Passage {
                let addPassageVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPassageViewController") as! AddPassageViewController
                addPassageVC.groupUID = self.groupUID
                addPassageVC.lesson = self.lesson
                addPassageVC.passageToEdit = (element as! Passage)
                self.navigationController?.pushViewController(addPassageVC, animated: true)
            }
            if element is MultipleChoiceQuestion {
                let mcq = (element as! MultipleChoiceQuestion)
                if mcq.correctMembers == nil && mcq.incorrectMembers == nil {
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    
                    alert.addAction(UIAlertAction(title: "Edit Question", style: .default, handler: { (UIAlertAction) -> Void in
                        let addMultipleChoiceQuestionVC = self.storyboard?.instantiateViewController(withIdentifier: "AddMultipleChoiceQuestionViewController") as! AddMultipleChoiceQuestionViewController
                        addMultipleChoiceQuestionVC.groupUID = self.groupUID
                        addMultipleChoiceQuestionVC.lesson = self.lesson
                        addMultipleChoiceQuestionVC.mcqToEdit = (element as! MultipleChoiceQuestion)
                        self.navigationController?.pushViewController(addMultipleChoiceQuestionVC, animated: true)
                    }))

                    alert.addAction(UIAlertAction(title: "See Results", style: .default, handler: { (UIAlertAction) -> Void in
                        print("See Results")
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("See Results")
                }
            }
        } else {
            if element is MultipleChoiceQuestion {
                print("See Results")
            }
        }
        
    }
    
}
