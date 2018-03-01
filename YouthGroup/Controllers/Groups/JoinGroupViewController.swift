//
//  JoinGroupViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/15/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol JoinGroupViewControllerDelegate: class {
    func refreshAccountDetail(reloadGroupsOnly: Bool)
}

class JoinGroupViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var skipJoinGroupButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    let reloadAccountName = Notification.Name(NotificationKeys.reloadAccount)
    
    var groupUIDs: [String]?
    var groups: [Group] = []
    
    weak var delegate: JoinGroupViewControllerDelegate?
    var restorationID: String!
    
    var tableViewHeightWithKeyboard: CGFloat!
    var tableViewHeightWithoutKeyboard: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        setSearchCriteria()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.tabBarController?.tabBar.isHidden = true
        
        restorationID = self.navigationController?.restorationIdentifier
        
        tableViewHeightWithoutKeyboard = tableView.frame.size.height - searchController.searchBar.frame.size.height
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let restorationID = self.navigationController?.restorationIdentifier
        self.navigationItem.hidesBackButton = (restorationID == "LoginNavigationController")
        
        KeyboardNotifications.subscribe(vc: self, showSelector: #selector(CreateGroupViewController.keyboardWillShow(notification:)), hideSelector: #selector(CreateGroupViewController.keyboardWillHide(notification:)))
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        KeyboardNotifications.unsubscribe(vc: self)
    }
    
    func performSearch(key: String) {
        let query = searchController.searchBar.text!.lowercased()
        if !query.isEmpty {
            FirebaseClient.shared.queryGroups(query: query, searchKey: key) { (groups, error) -> () in
                if let groups = groups {
                    self.groups = groups
                    self.tableView.reloadData()
                }
            }
        } else {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func criteriaButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: Helper.getString(key: "setSearchCriteria"), message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: Helper.getString(key: "byChurchName"), style: .default, handler: { (UIAlertAction) -> Void in
            UserDefaults.standard.set(0, forKey: "searchCriteria")
            self.setSearchCriteria()
        }))
        alert.addAction(UIAlertAction(title: Helper.getString(key: "byLeaderName"), style: .default, handler: { (UIAlertAction) -> Void in
            UserDefaults.standard.set(1, forKey: "searchCriteria")
            self.setSearchCriteria()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func setSearchCriteria() {
        switch UserDefaults.standard.integer(forKey: "searchCriteria") {
        case 0:
            searchController.searchBar.placeholder = Helper.getString(key: "enterChurchName")
            performSearch(key: "lowercasedChurch")
        case 1:
            searchController.searchBar.placeholder = Helper.getString(key: "enterLeaderName")
            performSearch(key: "lowercasedCreatedBy")
        default:
            searchController.searchBar.placeholder = Helper.getString(key: "enterChurchName")
            performSearch(key: "lowercasedChurch")
        }
    }
    
    @IBAction func skipJoinGroupButtonPressed(_ sender: Any) {
        UserDefaults.standard.set(Tabs.account.rawValue, forKey: "tabToDisplay")
        self.navigationController?.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: reloadAccountName, object: nil)
    }
    
}

extension JoinGroupViewController: UISearchResultsUpdating {
    func updateSearchResults(for: UISearchController) {
        if searchController.isActive {
            switch UserDefaults.standard.integer(forKey: "searchCriteria") {
            case 0: performSearch(key: "lowercasedChurch")
            case 1: performSearch(key: "lowercasedCreatedBy")
            default: ()
            }
        }
    }
}

extension JoinGroupViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
}

extension JoinGroupViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "joinGroupCell") as! JoinGroupCell
        let group = groups[indexPath.row]
        cell.setUp(group: group)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        searchController.isActive = false
        tableView.deselectRow(at: indexPath, animated: false)
        let selectedGroup = groups[indexPath.row]
        
        let members = Helper.combineLeadersAndStudents(group: selectedGroup)

        if let email = Auth.auth().currentUser?.email {
            let emails = members.map { $0.email }
            if emails.contains(where: {$0 == email}) {
                Alert.showBasic(title: Helper.getString(key: "cannotJoin"), message: Helper.getString(key: "cannotJoinMessage"), vc: self)
            }
        }
        
        let alertController = UIAlertController(title: Helper.getString(key: "passwordRequired"), message: Helper.getString(key: "passwordRequiredMessage"), preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: Helper.getString(key: "submit"), style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if selectedGroup.password == field.text {
                    if let email = Auth.auth().currentUser?.email {
                        self.joinGroup(email: email, group: selectedGroup)
                    }
                } else {
                    Alert.showBasic(title: Helper.getString(key: "incorrectPassword"), message: Helper.getString(key: "tryAgain"), vc: self)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: Helper.getString(key: "cancel"), style: .cancel, handler: nil)
        
        alertController.addTextField { (textField) in
            textField.textAlignment = .center
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func joinGroup(email: String, group: Group) {
        FirebaseClient.shared.appendUserGroup(email: email, newGroupUID: group.uid!, completion: { (success, error) in
            if let error = error {
                Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
            } else {
                self.updateGroupMembers(group: group)
            }
        })
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func updateGroupMembers(group: Group) {
        if let user = Auth.auth().currentUser {
            let newStudent = Member(email: user.email!, name: user.displayName!, leader: false)
            FirebaseClient.shared.appendGroupMember(uid: group.uid!, newMember: newStudent, type: "students", completion: { (success, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    let completion: (UIAlertAction) -> Void = {_ in
                        NotificationCenter.default.post(name: self.reloadAccountName, object: nil)
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                    UserDefaults.standard.setValue(group.uid!, forKey: "currentGroup")
                    Alert.showBasicWithCompletion(title: self.getString(key: "success"), message: self.getString(key: "joinedGroupMessage"), vc: self, completion: completion)
                }
            })
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let keyboardHeight = KeyboardNotifications.getKeyboardHeight(notification: notification)
        tableViewHeightWithKeyboard = tableViewHeightWithoutKeyboard - keyboardHeight
        tableView.frame.size.height = tableViewHeightWithKeyboard
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        tableView.frame.size.height = tableViewHeightWithoutKeyboard
    }
    
    func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
}
