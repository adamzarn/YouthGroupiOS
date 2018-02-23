//
//  AccountDetailViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

enum Sections: Int {
    case details = 0
    case currentGroup = 1
    case otherGroups = 2
}

class AccountDetailViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    var chosenImage: UIImage?
    var groupUIDs: [String]?
    var currentGroup: Group?
    var otherGroups: [Group] = []
    var reloadGroupsOnly = false
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(AccountDetailViewController.refreshAccountDetail), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        Aiv.show(aiv: aiv)
        self.tableView.isHidden = true
        if Auth.auth().currentUser == nil {
            if FBSDKAccessToken.current() != nil {
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                FirebaseClient.shared.signInWith(credential: credential, completion: { (user, error) in
                    if let user = user {
                        FirebaseClient.shared.setUserData(user: user)
                        self.reloadTableView()
                    }
                })
            }
        }

    }
    
    func reloadTableView() {
        
        if reloadGroupsOnly {
            let sections = IndexSet(integersIn: 1...2)
            tableView.reloadSections(sections, with: .automatic)
        } else {
            refreshControl.endRefreshing()
            tableView.reloadData()
            tableView.isHidden = false
            Aiv.hide(aiv: aiv)
        }
        
    }
    
    func getGroupUIDs(email: String) {
        FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let groupUIDs = groupUIDs {
                    self.groupUIDs = groupUIDs
                    self.getGroups(groupUIDs: groupUIDs)
                } else {
                    self.reloadTableView()
                }
            }
        })
    }
    
    func getGroups(groupUIDs: [String]) {
        let totalGroups = groupUIDs.count
        var fetchedGroups = 0
        for groupUID in groupUIDs {
            let currentGroupUID = UserDefaults.standard.string(forKey: "currentGroup")
            FirebaseClient.shared.getGroup(groupUID: groupUID, completion: { (group, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    fetchedGroups += 1
                    if let group = group, let uid = group.uid {
                        if currentGroupUID == uid {
                            self.currentGroup = group
                        } else {
                            self.otherGroups.append(group)
                        }
                    }
                    if fetchedGroups == totalGroups {
                        if self.otherGroups.count > 0 && self.currentGroup == nil {
                            self.currentGroup = self.otherGroups.removeFirst()
                            UserDefaults.standard.setValue(self.currentGroup?.uid!, forKey: "currentGroup")
                        }
                        self.reloadTableView()
                    }
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tabBarController?.tabBar.isHidden = false
        let name = Notification.Name(rawValue: NotificationKeys.reloadAccount)
        let selector = #selector(AccountDetailViewController.refresh)
        NotificationCenter.default.addObserver(self, selector:selector, name: name, object: nil)
        refreshAccountDetail(reloadGroupsOnly: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            FirebaseClient.shared.signOut(completion: { (success, error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if success {
                        self.appDelegate.userData = nil
                        self.presentLoginView()
                    }
                }
            })
        }
        if FBSDKAccessToken.current() != nil {
            FBSDKLoginManager().logOut()
            appDelegate.userData = nil
            presentLoginView()
        }
    }
    
    func presentLoginView() {
        let loginNC = storyboard?.instantiateViewController(withIdentifier: "LoginNavigationController") as! UINavigationController
        let loginVC = loginNC.viewControllers[0] as! LoginViewController
        loginVC.delegate = self
        self.present(loginNC, animated: false, completion: nil)
    }
    
    func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
}

//UITableViewDelegate and DataSource
extension AccountDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 || indexPath.section == 2 {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let group = (indexPath.section == 1) ? currentGroup! : otherGroups[indexPath.row]
            let isCurrentGroup = (indexPath.section == 1)
            if isOnlyLeader(group: group) {
                Alert.showBasic(title: "Cannot Delete", message: "You cannot delete this group because you are its only leader.", vc: self)
            } else {
                removeGroup(group: group, isCurrentGroup: isCurrentGroup)
            }
        }
    }
    
    func removeGroup(group: Group, isCurrentGroup: Bool) {
        
        if isCurrentGroup {
            if otherGroups.count > 0 {
                UserDefaults.standard.set(otherGroups[0].uid, forKey: "currentGroup")
            } else {
                UserDefaults.standard.set(nil, forKey: "currentGroup")
            }
        }

        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.deleteUserGroup(email: email, groupUIDToDelete: group.uid!, completion: { (success, error) in
                if let error = error {
                    Alert.showBasic(title: "Cannot Delete", message: error, vc: self)
                } else {
                    self.updateGroupMembers(group: group, email: email)
                }
            })
        }
    }
    
    func updateGroupMembers(group: Group, email: String) {
        let memberType = Helper.isLeader(group: group) ? "leaders" : "students"
        FirebaseClient.shared.deleteGroupMember(uid: group.uid!, email: email, type: memberType, completion: { (success, error) in
            if let error = error {
                Alert.showBasic(title: "Cannot Delete", message: error, vc: self)
            } else {
                self.refreshAccountDetail(reloadGroupsOnly: true)
            }
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Sections.details.rawValue:
            return appDelegate.userData?.count ?? 0
        case Sections.currentGroup.rawValue:
            if self.currentGroup != nil { return 1 }
            return 0
        case Sections.otherGroups.rawValue:
            return otherGroups.count + 2
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Sections.details.rawValue {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell") as! ProfileCell
                cell.delegate = self
                cell.setUp(image: self.chosenImage, user: Auth.auth().currentUser)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "accountDetailCell") as! AccountDetailCell
                cell.textLabel?.text = appDelegate.userData?[indexPath.row].0
                cell.detailTextLabel?.text = appDelegate.userData?[indexPath.row].1
                cell.setUp()
                return cell
            }
        } else if indexPath.section == Sections.currentGroup.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell")! as UITableViewCell
            if Helper.isLeader(group: self.currentGroup!) {
                cell.accessoryType = .detailDisclosureButton
            } else {
                cell.accessoryType = .none
            }
            cell.selectionStyle = .none
            cell.textLabel?.text = currentGroup!.church
            cell.detailTextLabel?.text = currentGroup!.nickname
            return cell
        } else {
            if indexPath.row < otherGroups.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell")! as UITableViewCell
                let currentGroup = otherGroups[indexPath.row]
                if Helper.isLeader(group: currentGroup) {
                    cell.accessoryType = .detailDisclosureButton
                } else {
                    cell.accessoryType = .none
                }
                cell.textLabel?.text = currentGroup.church
                cell.detailTextLabel?.text = currentGroup.nickname
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell") as! ButtonCell
                cell.delegate = self
                if indexPath.row == otherGroups.count {
                    cell.setUp(title: getString(key: "joinGroup"), buttonType: ButtonType.join)
                } else {
                    cell.setUp(title: getString(key: "createGroup"), buttonType: ButtonType.create)
                }
                return cell
            }
        }
    }
    
    func isOnlyLeader(group: Group) -> Bool {
        if let leaders = group.leaders {
            if Helper.isLeader(group: group) && leaders.count == 1 {
                return true
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Current Group"
        case 2:
            if otherGroups.count > 0 { return "Other Groups" }
            return nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 120.0
        } else if indexPath.section == 0 {
            return 44.0
        }
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == Sections.currentGroup.rawValue {
            let membersNC = self.storyboard?.instantiateViewController(withIdentifier: "MembersNavigationController") as! UINavigationController
            present(membersNC, animated: true, completion: nil)
        }
        if indexPath.section == Sections.otherGroups.rawValue && indexPath.row < otherGroups.count {
            let alert = UIAlertController(title: "Set Current Group", message: "Would you like to make \(otherGroups[indexPath.row].church!) your current group?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) -> Void in
                self.otherGroups.append(self.currentGroup!)
                self.currentGroup = self.otherGroups[indexPath.row]
                self.otherGroups.remove(at: indexPath.row)
                UserDefaults.standard.setValue(self.currentGroup?.uid!, forKey: "currentGroup")
                let sections = IndexSet(integersIn: 1...2)
                self.tableView.reloadSections(sections, with: .automatic)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        var groupToEdit: Group
        if indexPath.section == 1 {
            groupToEdit = currentGroup!
        } else {
            groupToEdit = otherGroups[indexPath.row]
        }
        let createGroupNC = self.storyboard?.instantiateViewController(withIdentifier: "CreateGroupNavigationController") as! UINavigationController
        let createGroupVC = createGroupNC.viewControllers[0] as! CreateGroupViewController
        createGroupVC.delegate = self
        createGroupVC.groupToEdit = groupToEdit
        present(createGroupNC, animated: true, completion: nil)
    }
    
}

extension AccountDetailViewController: ProfileCellDelegate {
    
    @objc func didTapProfileImageView(imageData: Data?) {
        let addPhotoNC = self.storyboard?.instantiateViewController(withIdentifier: "AddPhotoNavigationController") as! UINavigationController
        let addPhotoVC = addPhotoNC.viewControllers[0] as! AddPhotoViewController
        addPhotoVC.delegate = self
        addPhotoVC.imageData = imageData
        addPhotoVC.chosenImage = chosenImage
        addPhotoVC.cancelButton.tintColor = nil
        addPhotoVC.cancelButton.isEnabled = true
        addPhotoVC.skipAddPhotoButton.tintColor = .clear
        addPhotoVC.skipAddPhotoButton.isEnabled = false
        present(addPhotoNC, animated: true, completion: nil)
    }
    
    @objc func didSetProfilePhoto(image: UIImage?) {
        self.chosenImage = image
    }

}

extension AccountDetailViewController: AddPhotoViewControllerDelegate {
    
    func setChosenProfilePhoto(chosenImage: UIImage?) {
        self.chosenImage = chosenImage
        let firstRow = IndexPath(row: 0, section: 0)
        tableView.reloadRows(at: [firstRow], with: .none)
    }
    
}

extension AccountDetailViewController: ButtonCellDelegate {
    func didSelectButton(buttonType: ButtonType) {
        if buttonType == .join {
            let joinGroupNC = self.storyboard?.instantiateViewController(withIdentifier: "JoinGroupNavigationController") as! UINavigationController
            let joinGroupVC = joinGroupNC.viewControllers[0] as! JoinGroupViewController
            joinGroupVC.delegate = self
            joinGroupVC.groupUIDs = groupUIDs
            joinGroupVC.skipJoinGroupButton.tintColor = .clear
            joinGroupVC.skipJoinGroupButton.isEnabled = false
            joinGroupVC.cancelButton.tintColor = nil
            joinGroupVC.cancelButton.isEnabled = true
            present(joinGroupNC, animated: true)
        } else if buttonType == .create {
            let createGroupNC = self.storyboard?.instantiateViewController(withIdentifier: "CreateGroupNavigationController") as! UINavigationController
            let createGroupVC = createGroupNC.viewControllers[0] as! CreateGroupViewController
            createGroupVC.delegate = self
            createGroupVC.groupUIDs = groupUIDs
            createGroupVC.groupToEdit = nil
            present(createGroupNC, animated: true, completion: nil)
        }
    }
}

extension AccountDetailViewController: CreateGroupViewControllerDelegate, JoinGroupViewControllerDelegate, LoginViewControllerDelegate {
    
    @objc func refresh() {
        refreshAccountDetail(reloadGroupsOnly: false)
    }
    
    @objc func refreshAccountDetail(reloadGroupsOnly: Bool) {
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tabBarController?.tabBar.isHidden = false
        
        self.reloadGroupsOnly = reloadGroupsOnly
        
        if !reloadGroupsOnly {
            Aiv.show(aiv: aiv)
            tableView.isHidden = true
            tableView.setContentOffset(CGPoint.zero, animated: false)
        }

        UserDefaults.standard.setValue(Tabs.account.rawValue, forKey: "tabToDisplay")
        chosenImage = nil
        if let email = Auth.auth().currentUser?.email {
            groupUIDs = []
            currentGroup = nil
            otherGroups = []
            getGroupUIDs(email: email)
        }
    }
}
