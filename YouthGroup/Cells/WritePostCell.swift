
//
//  PostCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/26/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

protocol WritePostCellDelegate: class {
    func push(post: Post)
}

class WritePostCell: UITableViewCell {
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var postButton: YouthGroupButton!
    
    var member: Member!
    var groupUID: String?
    var savedEmail: String!
    
    weak var delegate: WritePostCellDelegate?
    
    override func awakeFromNib() {
        let selector = #selector(WritePostCell.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        postTextView.inputAccessoryView = toolbar
    }
    
    func setUp(groupUID: String?) {
        if let member = Helper.createMemberFromUser() {
            self.member = member
            self.groupUID = groupUID
            savedEmail = member.email!
            memberImageView.image = UIImage(named: "Boy")
        
            if let image = imageCache[member.email!] {
                self.memberImageView.image = image
            } else {
                FirebaseClient.shared.getProfilePhoto(email: member.email!, completion: { (data, error) in
                    if let data = data {
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            if self.savedEmail == member.email! {
                                self.memberImageView.image = image
                            }
                            imageCache[member.email!] = image
                        }
                    }
                })
            }
        }
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        let text = postTextView.text!
        if !text.isEmpty && text != "Write Post..." {
            if let groupUID = self.groupUID {
                postTextView.text = "Write Post..."
                postTextView.textColor = UIColor.lightGray
                let post = Post(uid: nil, email: member.email, name: member.name, timestamp: -1*Int64(Helper.getCurrentDateAndTime())!, text: text, comments: nil)
                FirebaseClient.shared.pushPost(groupUID: groupUID, post: post, completion: { error in
                    if error == nil {
                        self.delegate?.push(post: post)
                    }
                })
            }
        }
    }
    
}
