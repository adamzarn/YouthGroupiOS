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

enum EventsType: Int {
    case upcoming = 0
    case past = 1
}

class EventsViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    let threshold = CGFloat(10.0)
    var groupUID: String?
    var events: [Event] = []
    var eventsByDay: [[Event]] = []
    var uniqueDates: [String] = []
    var isLeader: Bool?
    var allLoaded = false
    var isLoadingMore = false
    var lastEventDate: String?
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    var scrollingLocked = true
    
    override func viewDidLayoutSubviews() {
        scrollingLocked = false
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        startGettingEvents()
    }
    
    @IBOutlet weak var aivView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createEventButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(EventsViewController.refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.rowHeight = 90.0
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createEventButton.isEnabled = false
        createEventButton.tintColor = .clear
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup"), let email = Auth.auth().currentUser?.email {
            self.groupUID = groupUID
            checkIfIsLeader(groupUID: groupUID, email: email)
        }
        self.tabBarController?.tabBar.isHidden = false
        refresh()
    }
    
    @objc func refresh() {
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
            self.groupUID = groupUID
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
                        self.startGettingEvents()
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(events: [])
                    }
                }
            })
        }
    }

    func startGettingEvents() {
        if segmentedControl.selectedSegmentIndex == EventsType.upcoming.rawValue {
            getEvents(groupUID: groupUID!, start: Helper.getTodayString(), end: nil)
        } else {
            getEvents(groupUID: groupUID!, start: nil, end: Helper.getTodayString())
        }
    }
    
    func checkIfIsLeader(groupUID: String, email: String) {
        FirebaseClient.shared.isLeader(groupUID: groupUID, email: email, completion: { (isLeader, error) in
            if let error = error {
                Aiv.hide(aiv: self.aiv)
                self.aivView.isHidden = true
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                self.isLeader = isLeader
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
    
    func getEvents(groupUID: String, start: String?, end: String?) {
        self.events = []
        FirebaseClient.shared.queryEvents(groupUID: groupUID, start: start, end: end, completion: { (events, error) in
            Aiv.hide(aiv: self.aiv)
            self.aivView.isHidden = true
            self.allLoaded = false
            self.lastEventDate = nil
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let events = events {
                    let firstEvents = events.sorted(by: { $0.date < $1.date })
                    self.lastEventDate = firstEvents.last?.date
                    self.events = firstEvents
                    if events.count == QueryLimits.events {
                        self.events.remove(at: self.events.count - 1)
                    } else {
                        self.allLoaded = true
                    }
                    self.reloadTableView(events: self.events)
                }
            }
        })
    }
    
    func getMoreEvents(groupUID: String, start: String?, end: String?) {
        if !allLoaded {
            FirebaseClient.shared.queryEvents(groupUID: groupUID, start: start, end: end, completion: { (events, error) in
                Aiv.hide(aiv: self.aiv)
                self.aivView.isHidden = true
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let events = events {
                        if events.count == 1 {
                            self.allLoaded = true
                            self.events = self.events + events
                            self.reloadTableView(events: self.events)
                        } else {
                            let newEvents = events.sorted(by: { $0.date < $1.date })
                            self.lastEventDate = newEvents.last?.date
                            self.events = self.events + newEvents
                            self.events.remove(at: self.events.count - 1)
                            self.reloadTableView(events: self.events)
                        }
                    }
                }
            })
        } else {
            Aiv.hide(aiv: self.aiv)
            self.aivView.isHidden = true
        }
    }
    
    func filterEventsByDay() {
        eventsByDay = []
        let dates = events.map { $0.date }
        if segmentedControl.selectedSegmentIndex == EventsType.upcoming.rawValue {
            uniqueDates = Array(Set(dates)).sorted { $0 < $1 }
        } else {
            uniqueDates = Array(Set(dates)).sorted { $0 > $1 }
        }
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
        self.isLoadingMore = false
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func createEventButtonPressed(_ sender: Any) {
        let createEventVC = self.storyboard?.instantiateViewController(withIdentifier: "CreateEventViewController") as! CreateEventViewController
        createEventVC.groupUID = groupUID
        self.navigationController?.pushViewController(createEventVC, animated: true)
    }
    
}

extension EventsViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
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
                let event = eventsByDay[indexPath.section][indexPath.row]
                FirebaseClient.shared.deleteEvent(groupUID: groupUID, eventUID: event.uid!, completion: { error in
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
        return eventsByDay.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsByDay[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventCell
        let event = eventsByDay[indexPath.section][indexPath.row]
        cell.setUp(event: event, groupUID: groupUID!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let eventVC = self.storyboard?.instantiateViewController(withIdentifier: "EventViewController") as! EventViewController
        eventVC.groupUID = groupUID!
        eventVC.event = eventsByDay[indexPath.section][indexPath.row]
        self.navigationController?.pushViewController(eventVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let createEventVC = self.storyboard?.instantiateViewController(withIdentifier: "CreateEventViewController") as! CreateEventViewController
        createEventVC.groupUID = groupUID
        createEventVC.eventToEdit = eventsByDay[indexPath.section][indexPath.row]
        createEventVC.indexPath = indexPath
        self.navigationController?.pushViewController(createEventVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollingLocked {
            return
        }
        
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if !isLoadingMore && (maximumOffset - contentOffset < threshold) {
            self.isLoadingMore = true
            Aiv.show(aiv: self.aiv)
            self.aivView.isHidden = false
            self.getMoreEvents(groupUID: groupUID!, start: self.lastEventDate, end: nil)
        }
    }
    
}
