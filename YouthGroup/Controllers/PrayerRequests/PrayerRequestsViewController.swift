//
//  PrayerRequestsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class PrayerRequestsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var aivView: UIView!
    
    let threshold = CGFloat(10.0)
    var prayerRequests: [PrayerRequest] = []
    var refreshControl: UIRefreshControl!
    var groupUID: String?
    var allLoaded = false
    var lastPrayerRequestTimestamp: Int64?
    var isLoadingMore = false
    
    var scrollingLocked = true
    
    override func viewDidLayoutSubviews() {
        scrollingLocked = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(PrayerRequestsViewController.refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        if prayerRequests.count == 0 {
            refresh()
        }
    }
    
    @objc func refresh() {
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
            checkIfUserBelongsToGroup(groupUID: groupUID)
        } else {
            self.reloadTableView(prayerRequests: [])
        }
    }
    
    func checkIfUserBelongsToGroup(groupUID: String) {
        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
                if let error = error {
                    self.aivView.isHidden = true
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                        self.groupUID = groupUID
                        self.getPrayerRequests(groupUID: groupUID, start: nil)
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(prayerRequests: [])
                    }
                }
            })
        }
    }
    
    func getPrayerRequests(groupUID: String, start: Int64?) {
        self.prayerRequests = []
        FirebaseClient.shared.queryPrayerRequests(groupUID: groupUID, start: start, completion: { (prayerRequests, error) in
            self.aivView.isHidden = true
            self.allLoaded = false
            self.lastPrayerRequestTimestamp = nil
            if let error = error {
                self.aivView.isHidden = true
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let prayerRequests = prayerRequests {
                    let firstPrayerRequests = prayerRequests.sorted(by: { $0.timestamp < $1.timestamp })
                    self.lastPrayerRequestTimestamp = firstPrayerRequests.last?.timestamp
                    self.prayerRequests = firstPrayerRequests
                    if prayerRequests.count == QueryLimits.prayerRequests {
                        self.prayerRequests.remove(at: self.prayerRequests.count - 1)
                    } else {
                        self.allLoaded = true
                    }
                    self.reloadTableView(prayerRequests: self.prayerRequests)
                }
            }
        })
    }
    
    func getMorePrayerRequests(groupUID: String, start: Int64?) {
        if !allLoaded {
            FirebaseClient.shared.queryPrayerRequests(groupUID: groupUID, start: start, completion: { (prayerRequests, error) in
                self.aivView.isHidden = true
                if let error = error {
                    self.aivView.isHidden = true
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let prayerRequests = prayerRequests {
                        if prayerRequests.count == 1 {
                            self.allLoaded = true
                            self.prayerRequests = self.prayerRequests + prayerRequests
                            self.reloadTableView(prayerRequests: self.prayerRequests)
                        } else {
                            let newPrayerRequests = prayerRequests.sorted(by: { $0.timestamp < $1.timestamp })
                            self.lastPrayerRequestTimestamp = newPrayerRequests.last?.timestamp
                            self.prayerRequests = self.prayerRequests + newPrayerRequests
                            self.prayerRequests.remove(at: self.prayerRequests.count - 1)
                            self.reloadTableView(prayerRequests: self.prayerRequests)
                        }
                    }
                }
            })
        } else {
            self.aivView.isHidden = true
        }
    }
    
    func reloadTableView(prayerRequests: [PrayerRequest]) {
        self.prayerRequests = prayerRequests.sorted(by: { $0.timestamp < $1.timestamp })
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let addPrayerRequestVC = self.storyboard?.instantiateViewController(withIdentifier: "AddPrayerRequestViewController") as! AddPrayerRequestViewController
        addPrayerRequestVC.delegate = self
        self.navigationController?.pushViewController(addPrayerRequestVC, animated: true)
    }
    
}

extension PrayerRequestsViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let email = Auth.auth().currentUser?.email {
            if email == prayerRequests[indexPath.row].submittedByEmail {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let groupUID = self.groupUID {
                let prayerRequestUID = prayerRequests[indexPath.row].uid!
                FirebaseClient.shared.deletePrayerRequest(groupUID: groupUID, prayerRequestUID: prayerRequestUID, completion: { error in
                    if let error = error {
                        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                    }
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayerRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prayerRequestCell") as! PrayerRequestCell
        let request = prayerRequests[indexPath.row]
        cell.setUp(request: request)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let prayerRequestVC = self.storyboard?.instantiateViewController(withIdentifier: "PrayerRequestViewController") as! PrayerRequestViewController
        prayerRequestVC.prayerRequest = prayerRequests[indexPath.row]
        prayerRequestVC.indexPath = indexPath
        prayerRequestVC.groupUID = groupUID
        prayerRequestVC.delegate = self
        self.navigationController?.pushViewController(prayerRequestVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollingLocked {
            return
        }
        
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if !isLoadingMore && (maximumOffset - contentOffset < threshold) {
            self.isLoadingMore = true
            self.aivView.isHidden = false
            self.getMorePrayerRequests(groupUID: groupUID!, start: self.lastPrayerRequestTimestamp)
        }
    }
    
}

extension PrayerRequestsViewController: PrayerRequestViewControllerDelegate {

    func toggleAnswered(indexPath: IndexPath) {
        prayerRequests[indexPath.row].answered = !prayerRequests[indexPath.row].answered
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func update(prayingMembers: [Member], indexPath: IndexPath) {
        prayerRequests[indexPath.row].prayingMembers = prayingMembers
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
}

extension PrayerRequestsViewController: AddPrayerRequestViewControllerDelegate {
    func push(prayerRequest: PrayerRequest) {
        self.prayerRequests.insert(prayerRequest, at: 0)
        self.tableView.reloadData()
    }
    
}
