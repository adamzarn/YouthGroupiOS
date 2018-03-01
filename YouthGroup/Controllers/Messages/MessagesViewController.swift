//
//  MessagesViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/26/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class MessagesViewController: UIViewController {

    var isLoadingMore = false
    var lastPostTimestamp: Int64?
    var groupUID: String?
    var email: String?
    var posts: [Post] = []
    var allLoaded = false
    var firstTime = true
    
    var scrollingLocked = true
    
    override func viewDidLayoutSubviews() {
        scrollingLocked = false
    }
    
    @IBOutlet weak var churchLabel: UIBarButtonItem!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var aivView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        aiv.startAnimating()
        let currentGroupUID = UserDefaults.standard.string(forKey: "currentGroup")
        if currentGroupUID != groupUID || Auth.auth().currentUser?.email != email {
            isLoadingMore = true
            firstTime = true
            refresh()
        }
    }
    
    func refresh() {
        self.posts = []
        if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
            checkIfUserBelongsToGroup(groupUID: groupUID)
        } else {
            self.reloadTableView(posts: self.posts)
        }
    }
    
    func checkIfUserBelongsToGroup(groupUID: String) {
        if let email = Auth.auth().currentUser?.email {
            self.email = email
            FirebaseClient.shared.getGroupUIDs(email: email, completion: { (groupUIDs, error) in
                if let error = error {
                    Aiv.hide(aiv: self.aiv)
                    self.aivView.isHidden = true
                    self.reloadTableView(posts: [])
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let groupUIDs = groupUIDs, groupUIDs.contains(groupUID) {
                        self.startObservingNewPosts(groupUID: groupUID)
                        Helper.setChurchName(groupUID: groupUID, button: self.churchLabel)
                        self.groupUID = groupUID
                        self.getPosts(groupUID: groupUID, start: nil)
                    } else {
                        UserDefaults.standard.set(nil, forKey: "currentGroup")
                        self.reloadTableView(posts: self.posts)
                    }
                }
            })
        }
    }
    
    func startObservingNewPosts(groupUID: String) {
        FirebaseClient.shared.removeObservers(node: "Posts", uid: groupUID)
        FirebaseClient.shared.observeNewPosts(node: "Posts", uid: groupUID, completion: { (post, error) in
            if let error = error {
                self.reloadTableView(posts: [])
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let post = post, !self.firstTime {
                    self.posts.insert(post, at: 0)
                    self.tableView.reloadData()
                } else {
                    self.firstTime = false
                }
            }
        })
    }
    
    func getPosts(groupUID: String, start: Int64?) {
        self.posts = []
        FirebaseClient.shared.queryPosts(node: "Posts", uid: groupUID, start: start, completion: { (posts, error) in
            Aiv.hide(aiv: self.aiv)
            self.aivView.isHidden = true
            self.allLoaded = false
            self.lastPostTimestamp = nil
            if let error = error {
                self.reloadTableView(posts: [])
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let posts = posts {
                    let firstPosts = posts.sorted(by: { $0.timestamp < $1.timestamp })
                    self.lastPostTimestamp = firstPosts.last?.timestamp
                    self.posts = firstPosts
                    if posts.count == QueryLimits.posts {
                        self.posts.remove(at: self.posts.count - 1)
                    } else {
                        self.allLoaded = true
                    }
                    self.reloadTableView(posts: self.posts)
                }
            }
        })
    }
    
    func getMorePosts(groupUID: String, start: Int64?) {
        if !allLoaded {
            FirebaseClient.shared.queryPosts(node: "Posts", uid: groupUID, start: start, completion: { (posts, error) in
                Aiv.hide(aiv: self.aiv)
                self.aivView.isHidden = true
                if let error = error {
                    self.reloadTableView(posts: [])
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let posts = posts {
                        if posts.count == 1 {
                            self.allLoaded = true
                            self.posts = self.posts + posts
                            self.reloadTableView(posts: self.posts)
                        } else {
                            let newPosts = posts.sorted(by: { $0.timestamp < $1.timestamp })
                            self.lastPostTimestamp = newPosts.last?.timestamp
                            self.posts = self.posts + newPosts
                            self.posts.remove(at: self.posts.count - 1)
                            self.reloadTableView(posts: self.posts)
                        }
                    }
                }
            })
        } else {
            Aiv.hide(aiv: self.aiv)
            self.aivView.isHidden = true
        }
    }
    
    func reloadTableView(posts: [Post]) {
        self.posts = posts.sorted(by: { $0.timestamp < $1.timestamp })
        self.tableView.reloadData()
        self.isLoadingMore = false
    }
    
}

extension MessagesViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Posts"
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "writePostCell") as! WritePostCell
            cell.messagesDelegate = self
            cell.setUp(groupUID: self.groupUID, postUID: nil)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostCell
        let post = self.posts[indexPath.row]
        cell.setUp(post: post)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let commentsVC = self.storyboard?.instantiateViewController(withIdentifier: "CommentsViewController") as! CommentsViewController
        commentsVC.originalPost = posts[indexPath.row]
        self.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollingLocked {
            return
        }
        
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height

        if !isLoadingMore && (maximumOffset - contentOffset < Constants.threshold) {
            self.isLoadingMore = true
            Aiv.show(aiv: self.aiv)
            self.aivView.isHidden = false
            if let groupUID = groupUID {
                self.getMorePosts(groupUID: groupUID, start: self.lastPostTimestamp)
            }
        }
    }
    
}

extension MessagesViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write Post..." {
            textView.text = ""
            textView.textColor = UIColor.black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write Post..."
            textView.textColor = UIColor.lightGray
        }
        textView.resignFirstResponder()
    }
    
}

extension MessagesViewController: WritePostCellDelegate {
    
    func push(post: Post, groupUID: String) {
        if posts.count == 0 {
            firstTime = true
            posts.insert(post, at: 0)
            tableView.reloadData()
            startObservingNewPosts(groupUID: groupUID)
        }
    }
    
    func displayError(error: String) {
        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
    }
    
}
