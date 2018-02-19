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
    var groupUID: String?
    
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
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                        self.groupUID = groupUID
                        self.getPrayerRequests(groupUID: groupUID)
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(prayerRequests: [])
                    }
                }
            })
        }
    }
    
    @objc func getPrayerRequests(groupUID: String) {
        FirebaseClient.shared.getPrayerRequests(groupUID: groupUID, completion: { (prayerRequests, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let prayerRequests = prayerRequests {
                    self.reloadTableView(prayerRequests: prayerRequests)
                } else {
                    self.reloadTableView(prayerRequests: [])
                }
            }
        })
    }
    
    func reloadTableView(prayerRequests: [PrayerRequest]) {
        self.prayerRequests = prayerRequests.sorted(by: { $0.timestamp > $1.timestamp })
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let addPrayerRequestNC = self.storyboard?.instantiateViewController(withIdentifier: "AddPrayerRequestNavigationController") as! UINavigationController
        let addPrayerRequestVC = addPrayerRequestNC.viewControllers[0] as! AddPrayerRequestViewController
        addPrayerRequestVC.delegate = self
        present(addPrayerRequestNC, animated: true, completion: nil)
    }
    
}

extension PrayerRequestsViewController: UITableViewDelegate, UITableViewDataSource {
    
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
                    } else {
                        self.prayerRequests.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
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
        let prayerRequestNC = self.storyboard?.instantiateViewController(withIdentifier: "PrayerRequestNavigationController") as! UINavigationController
        let prayerRequestVC = prayerRequestNC.viewControllers[0] as! PrayerRequestViewController
        prayerRequestVC.delegate = self
        prayerRequestVC.prayerRequest = prayerRequests[indexPath.row]
        prayerRequestVC.indexPath = indexPath
        prayerRequestVC.groupUID = groupUID
        present(prayerRequestNC, animated: true, completion: nil)
    }
    
}

extension PrayerRequestsViewController: AddPrayerRequestViewControllerDelegate {
    func add(newPrayerRequest: PrayerRequest) {
        prayerRequests.insert(newPrayerRequest, at: 0)
        tableView.reloadData()
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
