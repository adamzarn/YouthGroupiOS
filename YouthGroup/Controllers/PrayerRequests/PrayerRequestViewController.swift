//
//  PrayerRequestViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/17/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol PrayerRequestViewControllerDelegate: class {
    func toggleAnswered(indexPath: IndexPath)
    func update(prayingMembers: [Member], indexPath: IndexPath)
}

class PrayerRequestViewController: UIViewController {
    
    var prayerRequest: PrayerRequest!
    var indexPath: IndexPath!
    var groupUID: String!
    var prayingMembers: [Member] = []
    weak var delegate: PrayerRequestViewControllerDelegate?
    
    @IBOutlet weak var answeredButton: UIButton!
    @IBOutlet weak var profileImageView: CircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var requestTextView: BorderedTextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var prayingButton: YouthGroupButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 60.0
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let prayingMembers = prayerRequest.prayingMembers {
            self.prayingMembers = prayingMembers
        } else {
            self.prayingMembers = []
        }
        
        nameLabel.text = "Submitted by \(prayerRequest.submittedBy)"
        titleLabel.text = prayerRequest.title
        timestampLabel.text = Helper.formattedTimestamp(ts: String(prayerRequest.timestamp), includeDate: true, includeTime: true)
        requestTextView.text = prayerRequest.request
        setProfileImage()
        setCheckmark(answered: prayerRequest.answered)
        setPrayingButton()
        
    }
    
    func currentUserIsPraying() -> Bool {
        if let member = Helper.createMemberFromUser() {
            if prayingMembers.contains(where: {$0.email == member.email }) {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    func setPrayingButton() {
        if let email = Auth.auth().currentUser?.email, email == prayerRequest.submittedByEmail {
            prayingButton.isHidden = true
        } else {
            if currentUserIsPraying() {
                prayingButton.setTitle("NOT PRAYING", for: .normal)
            } else {
                prayingButton.setTitle("PRAYING", for: .normal)
            }
            prayingButton.isHidden = false
        }
    }
    
    func setCheckmark(answered: Bool) {
        if prayerRequest.answered {
            answeredButton.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        } else {
            answeredButton.setImage(nil, for: .normal)
        }
    }
    
    func setProfileImage() {
        let email = prayerRequest.submittedByEmail
        if let image = imageCache[email] {
            profileImageView.image = image
        } else {
            FirebaseClient.shared.getProfilePhoto(email: email, completion: { (data, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        self.profileImageView.image = image
                        imageCache[email] = image
                    }
                }
            })
        }
    }
    
    @IBAction func toggleCheckmark(_ sender: Any) {
        if let email = Auth.auth().currentUser?.email, email == prayerRequest.submittedByEmail {
            let newStatus = !prayerRequest.answered
            FirebaseClient.shared.toggleAnswered(groupUID: groupUID, prayerRequestUID: prayerRequest.uid!, newStatus: newStatus, completion: { (error) in
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    self.delegate?.toggleAnswered(indexPath: self.indexPath)
                    self.prayerRequest.answered = newStatus
                    self.setCheckmark(answered: newStatus)
                }
            })
        } else {
            Alert.showBasic(title: Helper.getString(key: "notAllowed"), message: Helper.getString(key: "answeredPrayerNotAllowedMessage"), vc: self)
        }
    }
    
    @IBAction func togglePraying(_ sender: Any) {
        if let member = Helper.createMemberFromUser() {
            var newPrayingMembers = prayingMembers
            if let index = newPrayingMembers.index(where: { $0.email == member.email }) {
                newPrayingMembers.remove(at: index)
            } else {
                newPrayingMembers.insert(member, at: 0)
            }
            if prayingMembers.count < newPrayingMembers.count {
                appendPrayingMember(member: member, newPrayingMembers: newPrayingMembers)
            } else {
                deletePrayingMember(member: member, newPrayingMembers: newPrayingMembers)
            }
        }
    }
    
    func appendPrayingMember(member: Member, newPrayingMembers: [Member]) {
        FirebaseClient.shared.appendPrayingMember(groupUID: groupUID, prayerRequestUID: prayerRequest.uid!, newPrayingMember: member, completion: { (error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                self.prayingButton.setTitle("NOT PRAYING", for: .normal)
                self.prayingMembers = newPrayingMembers
                self.delegate?.update(prayingMembers: newPrayingMembers, indexPath: self.indexPath)
                self.tableView.reloadData()
            }
        })
    }
    
    func deletePrayingMember(member: Member, newPrayingMembers: [Member]) {
        FirebaseClient.shared.deletePrayingMember(groupUID: groupUID, prayerRequestUID: prayerRequest.uid!, prayingMemberToDelete: member, completion: { (error) in
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                self.prayingButton.setTitle("PRAYING", for: .normal)
                self.prayingMembers = newPrayingMembers
                self.delegate?.update(prayingMembers: newPrayingMembers, indexPath: self.indexPath)
                self.tableView.reloadData()
            }
        })
    }
    
}

extension PrayerRequestViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayingMembers.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Praying"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberCell") as! MemberCell
        let member = prayingMembers[indexPath.row]
        cell.setUp(member: member)
        return cell
    }
    
}
