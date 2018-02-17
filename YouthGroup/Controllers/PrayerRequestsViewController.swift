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
    var prayerRequests: [PrayerRequest] = []
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(PrayerRequestsViewController.refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
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
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { groupUIDs in
                if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                    self.getPrayerRequests(groupUID: groupUID)
                } else {
                    UserDefaults.standard.set(nil, forKey: "currentGroup")
                    self.reloadTableView(prayerRequests: [])
                }
            })
        }
    }
    
    @objc func getPrayerRequests(groupUID: String) {
        FirebaseClient.shared.getPrayerRequests(groupUID: groupUID, completion: { (prayerRequests) in
            if let prayerRequests = prayerRequests {
                self.reloadTableView(prayerRequests: prayerRequests)
            } else {
                self.reloadTableView(prayerRequests: [])
            }
        })
    }
    
    func reloadTableView(prayerRequests: [PrayerRequest]) {
        
        self.prayerRequests = prayerRequests.sorted(by: { $0.timestamp > $1.timestamp })
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
}

extension PrayerRequestsViewController: UITableViewDelegate, UITableViewDataSource {
    
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
    
}
