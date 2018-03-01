//
//  MembersViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import FirebaseAuth

class MembersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var members: [[Member]] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        refresh()
    }
    
    func refresh() {
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
            checkIfUserBelongsToGroup(groupUID: groupUID)
        } else {
            self.reloadTableView(members: [])
        }
    }
    
    func checkIfUserBelongsToGroup(groupUID: String) {
        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                        self.getMembers(groupUID: groupUID)
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(members: [])
                    }
                }
            })
        }
    }
    
    @objc func getMembers(groupUID: String) {
        FirebaseClient.shared.getGroup(groupUID: groupUID, completion: { (group, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let group = group {
                    if let leaders = group.leaders, let students = group.students {
                        let sortedLeaders = leaders.sorted(by: { $0.name < $1.name })
                        let sortedStudents = students.sorted(by: { $0.name < $1.name })
                        self.reloadTableView(members: [sortedLeaders, sortedStudents])
                    } else {
                        self.reloadTableView(members: [])
                    }
                }
            }
        })
    }
    
    func reloadTableView(members: [[Member]]) {
        self.members = members
        self.tableView.reloadData()
    }
    
}

extension MembersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let headers = ["Leaders","Students"]
        return headers[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell") as! MemberCell
        let member = members[indexPath.section][indexPath.row]
        cell.setUp(member: member)
        return cell
    }
    
}
