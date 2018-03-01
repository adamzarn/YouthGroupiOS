
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
    func push(post: Post, groupUID: String)
    func displayError(error: String)
}

protocol WriteCommentCellDelegate: class {
    func push(comment: Post, originalPostUID: String)
    func displayError(error: String)
}

class WritePostCell: UITableViewCell {
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var postButton: YouthGroupButton!
    
    weak var messagesDelegate: WritePostCellDelegate?
    weak var commentsDelegate: WriteCommentCellDelegate?
    
    var member: Member!
    var groupUID: String?
    var postUID: String?
    var savedEmail: String!
    
    override func awakeFromNib() {
        let selector = #selector(WritePostCell.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        postTextView.inputAccessoryView = toolbar
    }
    
    func setUp(groupUID: String?, postUID: String?) {
        if let member = Helper.createMemberFromUser() {
            self.member = member
            self.groupUID = groupUID
            self.postUID = postUID
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
        
        if let postUID = postUID {
            
            if !text.isEmpty && text != "Write Comment..." {
                
                let comment = Post(uid: nil, email: member.email, name: member.name, timestamp: -1*Int64(Helper.getCurrentDateAndTime())!, text: text)
                
                FirebaseClient.shared.doesRefExist(node: "Comments", uid: postUID, completion: { exists in
                    FirebaseClient.shared.pushComment(originalPostUID: postUID, comment: comment, completion: { (commentUID, error) in
                        if let error = error {
                            self.commentsDelegate?.displayError(error: error)
                        } else {
                            self.postTextView.text = "Write Comment..."
                            self.postTextView.textColor = UIColor.lightGray
                            if !exists {
                                comment.uid = commentUID
                                self.commentsDelegate?.push(comment: comment, originalPostUID: postUID)
                            }
                        }
                    })
                })
                
            }
            
        } else {
        
            if !text.isEmpty && text != "Write Post..." {
                if let groupUID = self.groupUID {
                    
                    let post = Post(uid: nil, email: member.email, name: member.name, timestamp: -1*Int64(Helper.getCurrentDateAndTime())!, text: text)
                    
                    FirebaseClient.shared.doesRefExist(node: "Posts", uid: groupUID, completion: { exists in
                        FirebaseClient.shared.pushPost(groupUID: groupUID, post: post, completion: { (postUID, error) in
                            if let error = error {
                                self.messagesDelegate?.displayError(error: error)
                            } else {
                                self.postTextView.text = "Write Post..."
                                self.postTextView.textColor = UIColor.lightGray
                                if !exists {
                                    post.uid = postUID
                                    self.messagesDelegate?.push(post: post, groupUID: groupUID)
                                }
                            }
                        })
                    })
                }
            }
        }
    }
    
}
