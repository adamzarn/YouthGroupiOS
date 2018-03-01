//
//  CreateGroupViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/15/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol CreateGroupViewControllerDelegate: class {
    func refreshAccountDetail(reloadGroupsOnly: Bool)
}

class CreateGroupViewController: UIViewController {
    
    @IBOutlet weak var churchTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var descriptionTextView: BorderedTextView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    var yOrigin: CGFloat!
    var yKeyboard: CGFloat!
    
    var groupUIDs: [String]?
    var groupToEdit: Group?
    var members: [Member] = []
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: CreateGroupViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yOrigin = (self.navigationController?.navigationBar.frame.size.height)! + UIApplication.shared.statusBarFrame.size.height
        
        let selector = #selector(CreateGroupViewController.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        descriptionTextView.inputAccessoryView = toolbar
        
    }
    
    //MARK: IBActions


    @IBAction func submitButtonPressed(_ sender: Any) {
    
        Aiv.show(aiv: aiv)
        do {
            try createGroup()
        } catch CreateGroupError.missingChurch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "missingChurch"), message: getString(key: "missingChurchMessage"), vc: self)
        } catch CreateGroupError.missingNickname {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "missingNickname"), message: getString(key: "missingNicknameMessage"), vc: self)
        } catch CreateGroupError.missingPassword {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "missingPassword"), message: getString(key: "missingPasswordMessage"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: getString(key: "error"), message: getString(key: "ue_m"), vc: self)
        }
    }
    
    func createGroup() throws {
        let church = churchTextField.text!
        let nickname = nicknameTextField.text!
        let password = passwordTextField.text!
        let description = descriptionTextView.text!
        
        if church.isEmpty {
            throw CreateGroupError.missingChurch
        }
        if nickname.isEmpty {
            throw CreateGroupError.missingNickname
        }
        if password.isEmpty {
            throw CreateGroupError.missingPassword
        }
        
        //Submit an edited Group
        if let groupToEdit = groupToEdit {
            
            let leaders = members.filter { $0.leader! }
            let students = members.filter { !$0.leader! }
            
            let group = Group(uid: groupToEdit.uid!, church: church, lowercasedChurch: church.lowercased(), nickname: nickname, password: password, createdBy: groupToEdit.createdBy, lowercasedCreatedBy: groupToEdit.lowercasedCreatedBy, createdByEmail: groupToEdit.createdByEmail, description: description, leaders: leaders, students: students)
            FirebaseClient.shared.editGroup(group: group, completion: { (error) in
                Aiv.hide(aiv: self.aiv)
                if let error = error {
                    Alert.showBasic(title: self.getString(key: "Error"), message: error, vc: self)
                } else {
                    let completion: (UIAlertAction) -> Void = {_ in
                        self.delegate?.refreshAccountDetail(reloadGroupsOnly: true)
                        self.navigationController?.popViewController(animated: true)
                    }
                    Alert.showBasicWithCompletion(title: self.getString(key: "success"), message: self.getString(key: "editedGroupMessage"), vc: self, completion: completion)
                }
            })
        } else {
        
        //Create a new group
            if let user = Auth.auth().currentUser, let createdBy = user.displayName, let createdByEmail = user.email {
                let group = Group(uid: nil, church: church, lowercasedChurch: church.lowercased(), nickname: nickname, password: password, createdBy: createdBy, lowercasedCreatedBy: createdBy.lowercased(), createdByEmail: createdByEmail, description: description, leaders: members, students: nil)
                FirebaseClient.shared.createGroup(group: group, completion: { (groupUID, error) in
                    if let groupUID = groupUID {
                        self.joinGroup(email: createdByEmail, groupUID: groupUID)
                    } else if let error = error {
                        Aiv.hide(aiv: self.aiv)
                        Alert.showBasic(title: self.getString(key: "Error"), message: error, vc: self)
                    }
                })
            }
        }
    }
    
    func joinGroup(email: String, groupUID: String) {
        FirebaseClient.shared.appendUserGroup(email: email, newGroupUID: groupUID, completion: { (success, error) in
            Aiv.hide(aiv: self.aiv)
            if let error = error {
                Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
            } else {
                let completion: (UIAlertAction) -> Void = {_ in
                    self.delegate?.refreshAccountDetail(reloadGroupsOnly: true)
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
                UserDefaults.standard.setValue(groupUID, forKey: "currentGroup")
                Alert.showBasicWithCompletion(title: self.getString(key: "success"), message: self.getString(key: "createdAndJoinedGroupMessage"), vc: self, completion: completion)
            }
        })
    }
    
    @objc func dismissKeyboard() {
        descriptionTextView.resignFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        KeyboardNotifications.subscribe(vc: self, showSelector: #selector(CreateGroupViewController.keyboardWillShow(notification:)), hideSelector: #selector(CreateGroupViewController.keyboardWillHide(notification:)))
        Aiv.hide(aiv: aiv)
        if let group = groupToEdit {
            title = "Edit Group"
            churchTextField.text = group.church
            nicknameTextField.text = group.nickname
            passwordTextField.text = group.password
            descriptionTextView.text = group.description ?? ""
            members = Helper.combineLeadersAndStudents(group: group)
            tableView.reloadData()
            tableView.isUserInteractionEnabled = true
        } else {
            title = "Create Group"
            if let user = Auth.auth().currentUser, let email = user.email, let name = user.displayName {
                members = [Member(email: email, name: name, leader: true)]
            }
            tableView.reloadData()
            tableView.isUserInteractionEnabled = false
        }
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        KeyboardNotifications.unsubscribe(vc: self)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if passwordTextField.isFirstResponder || descriptionTextView.isFirstResponder {
            let keyboardHeight = KeyboardNotifications.getKeyboardHeight(notification: notification)
            yKeyboard = (yOrigin - keyboardHeight)/2
            view.frame.origin.y = yKeyboard
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        view.frame.origin.y = 0
    }
                
    func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
}

extension CreateGroupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CreateGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Members"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "editMemberCell") as! EditMemberCell
        let member = members[indexPath.row]
        cell.delegate = self
        cell.setUp(member: member)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
}

extension CreateGroupViewController: EditMemberCellDelegate {
    func toggle(member: Member) {
        let leaders = members.filter { $0.leader! }
        if leaders.count == 1 && member.leader! {
            Alert.showBasic(title: Helper.getString(key: "notAllowed"), message: Helper.getString(key: "leaderExceptionMessage"), vc: self)
        } else {
            var updatedMember = member
            updatedMember.leader = !updatedMember.leader!
            var i = 0
            while i < members.count {
                if members[i].email == updatedMember.email {
                    break
                }
                i+=1
            }
            members[i] = updatedMember
            tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
        }
    }
}
