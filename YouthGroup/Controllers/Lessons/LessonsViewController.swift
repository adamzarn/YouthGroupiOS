//
//  LessonsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class LessonsViewController: UIViewController {
    
    @IBOutlet weak var createLessonButton: UIBarButtonItem!
    
    @IBOutlet weak var churchLabel: UIBarButtonItem!
    var groupUID: String?
    var lessons: [Lesson] = []
    var lessonsByDay: [[Lesson]] = []
    var uniqueDates: [String] = []
    var isLeader: Bool?
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 60.0
        createLessonButton.isEnabled = false
        createLessonButton.tintColor = .clear
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup"), let email = Auth.auth().currentUser?.email {
            createLessonButton.isEnabled = false
            createLessonButton.tintColor = .clear
            self.groupUID = groupUID
            checkIfIsLeader(groupUID: groupUID, email: email)
        }
        refresh()
    }
    
    @objc func refresh() {
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
            self.groupUID = groupUID
            checkIfUserBelongsToGroup(groupUID: groupUID)
        } else {
            self.reloadTableView(lessons: [])
        }
    }
    
    func checkIfUserBelongsToGroup(groupUID: String) {
        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                        Helper.setChurchName(groupUID: groupUID, button: self.churchLabel)
                        self.groupUID = groupUID
                        self.checkIfIsLeader(groupUID: groupUID, email: email)
                        self.getLessons(groupUID: groupUID)
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(lessons: [])
                    }
                }
            })
        }
    }
    
    func getLessons(groupUID: String) {
        FirebaseClient.shared.getLessons(groupUID: groupUID, completion: { (lessons, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let lessons = lessons {
                    self.reloadTableView(lessons: lessons)
                } else {
                    self.reloadTableView(lessons: [])
                }
            }
        })
    }
    
    func filterLessonsByDay() {
        lessonsByDay = []
        let dates = lessons.map { $0.date } as [String]
        uniqueDates = Array(Set(dates)).sorted()
        for date in uniqueDates {
            var tempArray: [Lesson] = []
            for lesson in lessons {
                if date == lesson.date {
                    tempArray.append(lesson)
                }
            }
            let sorted = tempArray.sorted(by: { $0.title < $1.title })
            lessonsByDay.append(sorted)
        }
    }
    
    func reloadTableView(lessons: [Lesson]) {
        self.lessons = lessons
        filterLessonsByDay()
        tableView.reloadData()
    }
    
    func checkIfIsLeader(groupUID: String, email: String) {
        FirebaseClient.shared.isLeader(groupUID: groupUID, email: email, completion: { (isLeader, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                self.isLeader = isLeader
                self.setUpCreateLessonButton(isLeader: isLeader)
            }
        })
    }
    
    func setUpCreateLessonButton(isLeader: Bool) {
        if isLeader {
            createLessonButton.isEnabled = true
            createLessonButton.tintColor = nil
        } else {
            createLessonButton.isEnabled = false
            createLessonButton.tintColor = .clear
        }
    }
    @IBAction func createLessonButtonPressed(_ sender: Any) {
        let createLessonVC = self.storyboard?.instantiateViewController(withIdentifier: "CreateLessonViewController") as! CreateLessonViewController
        createLessonVC.groupUID = groupUID
        self.navigationController?.pushViewController(createLessonVC, animated: true)
    }
    
}

extension LessonsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let isLeader = isLeader, isLeader {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let groupUID = groupUID {
                let lesson = lessonsByDay[indexPath.section][indexPath.row]
                FirebaseClient.shared.deleteLesson(groupUID: groupUID, lessonUID: lesson.uid!, completion: { error in
                    if let error = error {
                        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                    }
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = uniqueDates[section]
        let weekday = Helper.getDayOfWeek(dateString: date)
        let formattedDate = Helper.formattedDate(ts: date)
        
        return "\(weekday) \(formattedDate)"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return lessonsByDay.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessonsByDay[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lessonCell") as! LessonCell
        let lesson = lessonsByDay[indexPath.section][indexPath.row]
        cell.setUp(lesson: lesson, groupUID: groupUID!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let lesson = lessonsByDay[indexPath.section][indexPath.row]
        if lesson.locked {
            Alert.showBasic(title: Helper.getString(key: "locked"), message: Helper.getString(key: "lessonLockedMessage"), vc: self)
        } else {
            let lessonNC = self.storyboard?.instantiateViewController(withIdentifier: "LessonNavigationController") as! UINavigationController
            let lessonVC = lessonNC.viewControllers[0] as! LessonViewController
            lessonVC.groupUID = groupUID!
            lessonVC.lesson = lesson
            if let isLeader = isLeader {
                lessonVC.isLeader = isLeader
            }
            present(lessonNC, animated: true, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let createLessonNC = self.storyboard?.instantiateViewController(withIdentifier: "CreateLessonNavigationController") as! UINavigationController
        let createLessonVC = createLessonNC.viewControllers[0] as! CreateLessonViewController
        createLessonVC.groupUID = groupUID
        createLessonVC.lessonToEdit = lessonsByDay[indexPath.section][indexPath.row]
        present(createLessonNC, animated: true, completion: nil)
    }
    
}
