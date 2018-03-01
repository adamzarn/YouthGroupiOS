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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var lesson: Lesson!
    var groupUID: String!
    var isLeader = false
    var checkedInMembers: [Member]?
    
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
        FirebaseClient.shared.checkInToLesson(groupUID: groupUID, lessonUID: lesson.uid!, completion: { (error) in
            if error == nil {
                self.appDelegate.groupUID = self.groupUID
                self.appDelegate.lessonUID = self.lesson.uid!
            }
        })
        FirebaseClient.shared.getCheckedInMembers(groupUID: groupUID, lessonUID: lesson.uid!, completion: { (checkedInMembers, error) in
            if let checkedInMembers = checkedInMembers {
                self.checkedInMembers = checkedInMembers
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        })
    }
    
    func checkOut() {
        FirebaseClient.shared.checkOutOfLesson(groupUID: groupUID, lessonUID: lesson.uid!, completion: { (error) in })
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
        let actionSheet = UIAlertController(title: Helper.getString(key: "addLessonElement"), message: nil, preferredStyle: .actionSheet)
        
        let activity = UIAlertAction(title: Helper.getString(key: "activity"), style: .default, handler: { (UIAlertAction) -> Void in
            let addActivityVC = self.storyboard?.instantiateViewController(withIdentifier: "AddActivityViewController") as! AddActivityViewController
            addActivityVC.groupUID = self.groupUID
            addActivityVC.lesson = self.lesson
            self.navigationController?.pushViewController(addActivityVC, animated: true)
        })
        let passage = UIAlertAction(title: Helper.getString(key: "biblePassage"), style: .default, handler: { (UIAlertAction) -> Void in
            let addPassageVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPassageViewController") as! AddPassageViewController
            addPassageVC.groupUID = self.groupUID
            addPassageVC.lesson = self.lesson
            self.navigationController?.pushViewController(addPassageVC, animated: true)
        })
        let multipleChoiceQuestion = UIAlertAction(title: Helper.getString(key: "multipleChoiceQuestion"), style: .default, handler: { (UIAlertAction) -> Void in
            let addMultipleChoiceQuestionVC = self.storyboard?.instantiateViewController(withIdentifier: "AddMultipleChoiceQuestionViewController") as! AddMultipleChoiceQuestionViewController
            addMultipleChoiceQuestionVC.groupUID = self.groupUID
            addMultipleChoiceQuestionVC.lesson = self.lesson
            self.navigationController?.pushViewController(addMultipleChoiceQuestionVC, animated: true)
        })
        let freeResponseQuestion = UIAlertAction(title: Helper.getString(key: "freeResponseQuestion"), style: .default, handler: { (UIAlertAction) -> Void in
            let addFreeResponseQuestionVC = self.storyboard?.instantiateViewController(withIdentifier: "AddFreeResponseQuestionViewController") as! AddFreeResponseQuestionViewController
            addFreeResponseQuestionVC.groupUID = self.groupUID
            addFreeResponseQuestionVC.lesson = self.lesson
            self.navigationController?.pushViewController(addFreeResponseQuestionVC, animated: true)
        })
        let cancel = UIAlertAction(title: Helper.getString(key: "cancel"), style: .cancel, handler: nil)
        
        actionSheet.addAction(activity)
        actionSheet.addAction(passage)
        actionSheet.addAction(multipleChoiceQuestion)
        actionSheet.addAction(freeResponseQuestion)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true, completion: nil)

    }
    
    @IBAction func dismissButtonPressed(sender: Any) {
        checkOut()
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
            tableView.reloadData()
        } else {
            editButton.title = "Edit"
            editButton.style = .plain
            tableView.isEditing = false
            tableView.reloadData()
        }
    }
    
    
}

extension LessonViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView.isEditing {
            return 100.0
        }
        
        if indexPath.row == 0 {
            return 100.0
        }
        if lesson.elements![indexPath.row - 1] is MultipleChoiceQuestion {
            let mcq = lesson.elements![indexPath.row - 1] as! MultipleChoiceQuestion
            let choices = mcq.incorrectAnswers.count + 1
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "multipleChoiceQuestionCell") as! MultipleChoiceQuestionCell
            
            let headerHeight = CGFloat(54.0)
            let questionHeight = cell.getQuestionLabelHeight(question: mcq.question)
            let choicesHeight = CGFloat(choices)*40.0
            let footerHeight = CGFloat(24.0)
            
            return headerHeight + questionHeight + choicesHeight + footerHeight
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
        if isLeader && indexPath.row != 0 { return true }; return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let elementToMove = lesson.elements![sourceIndexPath.row - 1]
        lesson.elements!.remove(at: sourceIndexPath.row - 1)
        lesson.elements!.insert(elementToMove, at: destinationIndexPath.row - 1)
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
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.row == 0 {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if isLeader && indexPath.row != 0 { return true }; return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let elementUID = lesson.elements![indexPath.row - 1].uid!
            FirebaseClient.shared.deleteElement(groupUID: groupUID, lessonUID: lesson.uid!, elementUID: elementUID, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let elements = lesson.elements {
            return elements.count + 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "checkedInMembersCell") as! CheckedInMembersCell
            if let checkedInMembers = checkedInMembers {
                cell.setUp(checkedInMembers: checkedInMembers)
            }
            return cell
        }
        
        let element = lesson.elements![indexPath.row - 1]
        switch element.type {
        case Elements.activity.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell") as! ActivityCell
            cell.setUp(activity: element as! Activity, editing: tableView.isEditing)
            return cell
        case Elements.passage.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "biblePassageCell") as! BiblePassageCell
            cell.setUp(passage: element as! Passage, groupUID: groupUID, editing: tableView.isEditing)
            return cell
        case Elements.multipleChoiceQuestion.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "multipleChoiceQuestionCell") as! MultipleChoiceQuestionCell
            cell.shouldIndentWhileEditing = false
            cell.setUp(mcq: element as! MultipleChoiceQuestion, groupUID: groupUID, lessonUID: lesson.uid!, editing: tableView.isEditing)
            return cell
        case Elements.freeResponseQuestion.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "freeResponseQuestionCell") as! FreeResponseQuestionCell
            cell.delegate = self
            cell.setUp(frq: element as! FreeResponseQuestion, groupUID: groupUID, lessonUID: lesson.uid!, editing: tableView.isEditing)
            return cell
        default:
            return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let element = lesson.elements![indexPath.row - 1]
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
                    
                    alert.addAction(UIAlertAction(title: Helper.getString(key: "editQuestion"), style: .default, handler: { (UIAlertAction) -> Void in
                        let addMultipleChoiceQuestionVC = self.storyboard?.instantiateViewController(withIdentifier: "AddMultipleChoiceQuestionViewController") as! AddMultipleChoiceQuestionViewController
                        addMultipleChoiceQuestionVC.groupUID = self.groupUID
                        addMultipleChoiceQuestionVC.lesson = self.lesson
                        addMultipleChoiceQuestionVC.mcqToEdit = (element as! MultipleChoiceQuestion)
                        self.navigationController?.pushViewController(addMultipleChoiceQuestionVC, animated: true)
                    }))

                    alert.addAction(UIAlertAction(title: Helper.getString(key: "seeResults"), style: .default, handler: { (UIAlertAction) -> Void in
                        self.goToMultipleChoiceResults(indexPath: indexPath)
                    }))
                    alert.addAction(UIAlertAction(title: Helper.getString(key: "cancel"), style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.goToMultipleChoiceResults(indexPath: indexPath)
                }
            }
            if element is FreeResponseQuestion {
                let frq = (element as! FreeResponseQuestion)
                if frq.answerers == nil {
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    
                    alert.addAction(UIAlertAction(title: Helper.getString(key: "editQuestion"), style: .default, handler: { (UIAlertAction) -> Void in
                        let addFreeResponseQuestionVC = self.storyboard?.instantiateViewController(withIdentifier: "AddFreeResponseQuestionViewController") as! AddFreeResponseQuestionViewController
                        addFreeResponseQuestionVC.groupUID = self.groupUID
                        addFreeResponseQuestionVC.lesson = self.lesson
                        addFreeResponseQuestionVC.frqToEdit = (element as! FreeResponseQuestion)
                        self.navigationController?.pushViewController(addFreeResponseQuestionVC, animated: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: Helper.getString(key: "seeResults"), style: .default, handler: { (UIAlertAction) -> Void in
                        self.goToFreeResponseAnswers(indexPath: indexPath)
                    }))
                    alert.addAction(UIAlertAction(title: Helper.getString(key: "cancel"), style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.goToFreeResponseAnswers(indexPath: indexPath)
                }
            }
        } else {
            if element is MultipleChoiceQuestion {
                let mcq = element as! MultipleChoiceQuestion
                if Helper.getCurrentAnswerer(correctMembers: mcq.correctMembers, incorrectMembers: mcq.incorrectMembers) != nil {
                    self.goToMultipleChoiceResults(indexPath: indexPath)
                }
            }
            if element is FreeResponseQuestion {
                let frq = element as! FreeResponseQuestion
                if Helper.getCurrentAnswerer(correctMembers: frq.answerers, incorrectMembers: nil) != nil {
                    self.goToFreeResponseAnswers(indexPath: indexPath)
                }
            }
        }
        
    }
    
    func goToMultipleChoiceResults(indexPath: IndexPath) {
        let resultsVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultsViewController") as! ResultsViewController
        resultsVC.mcq = lesson.elements![indexPath.row - 1] as! MultipleChoiceQuestion
        resultsVC.groupUID = groupUID
        resultsVC.lessonUID = lesson.uid!
        self.navigationController?.pushViewController(resultsVC, animated: true)
    }
    
    func goToFreeResponseAnswers(indexPath: IndexPath) {
        let answersVC = self.storyboard?.instantiateViewController(withIdentifier: "AnswersViewController") as! AnswersViewController
        answersVC.frq = lesson.elements![indexPath.row - 1] as! FreeResponseQuestion
        answersVC.groupUID = groupUID
        answersVC.lesson = lesson
        self.navigationController?.pushViewController(answersVC, animated: true)
    }
    
}

extension LessonViewController: FreeResponseQuestionCellDelegate {
    func didSumbitAnswer(error: String?) {
        if let error = error {
            Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
        } else {
            Alert.showBasic(title: Helper.getString(key: "success"), message: Helper.getString(key: "answerSuccessfullySubmitted"), vc: self)
        }
    }
}
