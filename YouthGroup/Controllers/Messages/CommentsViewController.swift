//
//  CommentsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 3/1/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class CommentsViewController: UIViewController {
    
    var postUID: String!
    var groupUID: String!
    var originalPost: Post!
    var lastCommentTimestamp: Int64?
    var allLoaded = false
    var isLoadingMore = false
    var firstTime = true
    
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    @IBOutlet weak var aivView: UIView!
    
    var comments: [Post] = []
    
    var scrollingLocked = true
    
    override func viewDidLayoutSubviews() {
        scrollingLocked = false
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        aiv.startAnimating()
        startObservingNewComments(originalPostUID: originalPost.uid!)
        getComments(originalPostUID: originalPost.uid!, start: nil)
    }
    
    func startObservingNewComments(originalPostUID: String) {
        FirebaseClient.shared.removeObservers(node: "Comments", uid: originalPostUID)
        FirebaseClient.shared.observeNewPosts(node: "Comments", uid: originalPostUID, completion: { (comment, error) in
            if let error = error {
                self.reloadTableView(comments: [])
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let comment = comment, !self.firstTime {
                    self.comments.insert(comment, at: 0)
                    self.tableView.reloadData()
                } else {
                    self.firstTime = false
                }
            }
        })
    }
    
    func getComments(originalPostUID: String, start: Int64?) {
        self.comments = []
        FirebaseClient.shared.queryPosts(node: "Comments", uid: originalPostUID, start: start, completion: { (comments, error) in
            Aiv.hide(aiv: self.aiv)
            self.aivView.isHidden = true
            self.allLoaded = false
            self.lastCommentTimestamp = nil
            if let error = error {
                self.reloadTableView(comments: [])
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                if let comments = comments {
                    let firstComments = comments.sorted(by: { $0.timestamp < $1.timestamp })
                    self.lastCommentTimestamp = firstComments.last?.timestamp
                    self.comments = firstComments
                    if comments.count == QueryLimits.posts {
                        self.comments.remove(at: self.comments.count - 1)
                    } else {
                        self.allLoaded = true
                    }
                    self.reloadTableView(comments: self.comments)
                }
            }
        })
    }
    
    func getMoreComments(originalPostUID: String, start: Int64?) {
        if !allLoaded {
            FirebaseClient.shared.queryPosts(node: "Comments", uid: originalPostUID, start: start, completion: { (comments, error) in
                Aiv.hide(aiv: self.aiv)
                self.aivView.isHidden = true
                if let error = error {
                    self.reloadTableView(comments: [])
                    Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                } else {
                    if let comments = comments {
                        if comments.count == 1 {
                            self.allLoaded = true
                            self.comments = self.comments + comments
                            self.reloadTableView(comments: self.comments)
                        } else {
                            let newComments = comments.sorted(by: { $0.timestamp < $1.timestamp })
                            self.lastCommentTimestamp = newComments.last?.timestamp
                            self.comments = self.comments + newComments
                            self.comments.remove(at: self.comments.count - 1)
                            self.reloadTableView(comments: self.comments)
                        }
                    }
                }
            })
        } else {
            Aiv.hide(aiv: self.aiv)
            self.aivView.isHidden = true
        }
    }
    
    func reloadTableView(comments: [Post]) {
        self.comments = comments.sorted(by: { $0.timestamp < $1.timestamp })
        self.tableView.reloadData()
        self.isLoadingMore = false
    }
    
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else if section == 1 {
            return "Comment"
        }
        return "Comments"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 2 {
            return 1
        } else {
            return comments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostCell
            cell.setUp(post: originalPost)
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "writeCommentCell") as! WritePostCell
            cell.commentsDelegate = self
            cell.setUp(groupUID: groupUID, postUID: originalPost.uid!)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostCell
            cell.setUp(post: comments[indexPath.row])
            return cell
        }

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
            self.getMoreComments(originalPostUID: originalPost.uid!, start: lastCommentTimestamp)
        }
    }

}

extension CommentsViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write Comment..." {
            textView.text = ""
            textView.textColor = UIColor.black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write Comment..."
            textView.textColor = UIColor.lightGray
        }
        textView.resignFirstResponder()
    }
    
}

extension CommentsViewController: WriteCommentCellDelegate {
    
    func push(comment: Post, originalPostUID: String) {
        if comments.count == 0 {
            firstTime = true
            comments.insert(comment, at: 0)
            tableView.reloadData()
            startObservingNewComments(originalPostUID: originalPostUID)
        }
    }
    
    func displayError(error: String) {
        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
    }
}
