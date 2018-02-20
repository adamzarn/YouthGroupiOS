//
//  EventsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class EventsViewController: UIViewController {
    
    var groupUID: String?
    var events: [Event] = []
    var eventsByDay: [[Event]] = []
    var uniqueDates: [String] = []
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createEventButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(PrayerRequestsViewController.refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
        self.createEventButton.isEnabled = false
        self.createEventButton.tintColor = .clear
    }
    
    @objc func refresh() {
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
            checkIfUserBelongsToGroup(groupUID: groupUID)
        } else {
            self.reloadTableView(events: [])
        }
    }
    
    func checkIfUserBelongsToGroup(groupUID: String) {
        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                        self.groupUID = groupUID
                        self.checkIfIsLeader(groupUID: groupUID, email: email)
                        self.getEvents(groupUID: groupUID)
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(events: [])
                    }
                }
            })
        }
    }
    
    func checkIfIsLeader(groupUID: String, email: String) {
        FirebaseClient.shared.isLeader(groupUID: groupUID, email: email, completion: { (isLeader, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                self.setUpCreateEventButton(isLeader: isLeader)
            }
        })
    }
    
    func setUpCreateEventButton(isLeader: Bool) {
        if isLeader {
            self.createEventButton.isEnabled = true
            self.createEventButton.tintColor = nil
        } else {
            self.createEventButton.isEnabled = false
            self.createEventButton.tintColor = .clear
        }
    }
    
    func getEvents(groupUID: String) {
        FirebaseClient.shared.getEvents(groupUID: groupUID, completion: { (events, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let events = events {
                    self.reloadTableView(events: events)
                } else {
                    self.reloadTableView(events: [])
                }
            }
        })
    }
    
    func filterEventsByDay() {
        eventsByDay = []
        let dates = events.map { $0.date }
        uniqueDates = Array(Set(dates)).sorted()
        for date in uniqueDates {
            var tempArray: [Event] = []
            for event in events {
                if date == event.date {
                    tempArray.append(event)
                }
            }
            let sorted = tempArray.sorted(by: { $0.startTime < $1.startTime })
            eventsByDay.append(sorted)
        }
    }
    
    func reloadTableView(events: [Event]) {
        self.events = events
        filterEventsByDay()
        tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func createEventButtonPressed(_ sender: Any) {
        let createEventNC = self.storyboard?.instantiateViewController(withIdentifier: "CreateEventNavigationController") as! UINavigationController
        //let createEventVC = createEventNC.viewControllers[0] as! CreateEventViewController
        present(createEventNC, animated: true, completion: nil)
    }
    
}

extension EventsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = uniqueDates[section]
        let weekday = Helper.getDayOfWeek(dateString: date)
        let formattedDate = Helper.formattedTimestamp(ts: date, includeDate: true, includeTime: false)
        
        return "\(weekday) \(formattedDate)"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return eventsByDay.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsByDay[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventCell
        let event = eventsByDay[indexPath.section][indexPath.row]
        cell.setUp(event: event)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let eventNC = self.storyboard?.instantiateViewController(withIdentifier: "EventNavigationController") as! UINavigationController
        let eventVC = eventNC.viewControllers[0] as! EventViewController
        eventVC.event = eventsByDay[indexPath.section][indexPath.row]
        present(eventNC, animated: true, completion: nil)
    }
    
}
