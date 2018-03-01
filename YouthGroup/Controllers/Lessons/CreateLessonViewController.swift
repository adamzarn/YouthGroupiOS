//
//  CreateLessonViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class CreateLessonViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lockedSwitch: UISwitch!
    
    var leaders: [[Member]] = [[],[]]
    
    let datePicker = UIDatePicker()
    var dateToSubmit: String?
    var lessonToEdit: Lesson?
    var groupUID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.datePickerMode = .date
        dateTextField.inputView = datePicker

        let selector = #selector(CreateLessonViewController.dismissPicker)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        dateTextField.inputAccessoryView = toolbar
        
        datePicker.addTarget(self, action: #selector(CreateLessonViewController.setDate(sender:)), for: .valueChanged)
        
        tableView.rowHeight = 60.0
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        getGroupLeaders()
        if let lesson = lessonToEdit {
            title = "Edit Lesson"
            titleTextField.text = lesson.title
            dateTextField.text = Helper.formattedDate(ts: lesson.date)
            lockedSwitch.isOn = lesson.locked
        } else {
            title = "Create Lesson"
            titleTextField.text = ""
            dateTextField.text = ""
            lockedSwitch.isOn = true
        }
    }
    
    func getGroupLeaders() {
        FirebaseClient.shared.getGroupLeaders(groupUID: groupUID, completion: { (leaders, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let leaders = leaders {
                    if let lessonToEdit = self.lessonToEdit {
                        self.setLeaders(leaders: leaders, lesson: lessonToEdit)
                        self.tableView.reloadData()
                    } else {
                        self.leaders[1] = leaders
                        self.tableView.reloadData()
                    }
                }
            }
        })
    }
    
    func setLeaders(leaders: [Member], lesson: Lesson) {
        self.leaders[0] = lesson.leaders
        let selectedLeaderEmails = lesson.leaders.map { $0.email } as! [String]
        for leader in leaders {
            let email = leader.email
            if !selectedLeaderEmails.contains(email!) {
                self.leaders[1].append(leader)
            }
        }
    }
    
    @objc func setDate(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateText = dateFormatter.string(from: sender.date)

        if dateTextField.isFirstResponder {
            dateToSubmit = dateText
            dateTextField.text = Helper.formattedDate(ts: dateText)
        }
    }
    
    func sortLeaders() {
        leaders[0] = leaders[0].sorted { $0.name < $1.name }
        leaders[1] = leaders[1].sorted { $0.name < $1.name }
    }
    
    @objc func dismissPicker() {
        self.view.endEditing(true)
    }
    
    func verifyLesson() throws {
        let title = titleTextField.text!
        let date = dateTextField.text!
        
        if title.isEmpty {
            throw CreateLessonError.missingTitle
        }
        if date.isEmpty {
            throw CreateLessonError.missingDate
        }
        if leaders[0].count == 0 {
            throw CreateLessonError.missingLeaders
        }
        
        var finalDate: String
        
        if let dateToSubmit = dateToSubmit {
            finalDate = dateToSubmit
        } else {
            finalDate = (lessonToEdit?.date)!
        }

        let lesson = Lesson(uid: nil, title: title, date: finalDate, locked: lockedSwitch.isOn, leaders: leaders[0], elements: nil)
        
        if let lessonToEdit = lessonToEdit {
            lesson.uid = lessonToEdit.uid
            lesson.elements = lessonToEdit.elements
            FirebaseClient.shared.editLesson(groupUID: groupUID, lesson: lesson, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "Error"), message: error, vc: self)
                } else {
                    let completion: (UIAlertAction) -> Void = {_ in
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: Helper.getString(key: "editedLessonMessage"), vc: self, completion: completion)
                }
            })
        } else {
            FirebaseClient.shared.createLesson(groupUID: groupUID, lesson: lesson, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "Error"), message: error, vc: self)
                } else {
                    let completion: (UIAlertAction) -> Void = {_ in
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: Helper.getString(key: "createdLessonMessage"), vc: self, completion: completion)
                }
            })
        }
        
    }
    

    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        do {
            try verifyLesson()
        } catch CreateLessonError.missingTitle {
            Alert.showBasic(title: Helper.getString(key: "missingTitle"), message: Helper.getString(key: "missingTitleMessage"), vc: self)
        } catch CreateLessonError.missingDate {
            Alert.showBasic(title: Helper.getString(key: "missingDate"), message: Helper.getString(key: "missingDateMessage"), vc: self)
        } catch CreateLessonError.missingLeaders {
            Alert.showBasic(title: Helper.getString(key: "missingLeaders"), message: Helper.getString(key: "missingLeadersMessage"), vc: self)
        } catch {
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
        
    }
    
}

extension CreateLessonViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension CreateLessonViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if leaders[0].count == 0 {
            switch section {
            case 0:
                return nil
            case 1:
                return "Select a Leader"
            default:
                return nil
            }
        } else {
            switch section {
            case 0:
                return "Selected Leaders"
            case 1:
                if leaders[1].count == 0 {
                    return nil
                } else {
                    return "Select another Leader"
                }
            default:
                return nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selectedLeader = leaders[indexPath.section][indexPath.row]
            if indexPath.section == 0 {
                leaders[0].remove(at: indexPath.row)
                leaders[1].append(selectedLeader)
                sortLeaders()
                tableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return leaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leaders[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell") as! MemberCell
        let leader = leaders[indexPath.section][indexPath.row]
        cell.setUp(member: leader)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedLeader = leaders[indexPath.section][indexPath.row]
        if indexPath.section == 1 {
            leaders[1].remove(at: indexPath.row)
            leaders[0].append(selectedLeader)
            sortLeaders()
            tableView.reloadData()
        }
    }
    
    
    
}
