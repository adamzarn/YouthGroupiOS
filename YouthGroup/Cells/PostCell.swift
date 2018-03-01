//
//  PostCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/26/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class PostCell: UITableViewCell {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var savedEmail: String!
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    func setUp(post: Post) {
        
        nameLabel.text = post.name
        postLabel.text = post.text
        timestampLabel.text = Helper.formattedTimestamp(ts: String(post.timestamp), includeDate: true, includeTime: true)
        
        savedEmail = post.email!
        self.memberImageView.image = UIImage(named: "Boy")
        
        if let image = imageCache[post.email!] {
            self.memberImageView.image = image
        } else {
            FirebaseClient.shared.getProfilePhoto(email: post.email!, completion: { (data, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        if self.savedEmail == post.email! {
                            self.memberImageView.image = image
                        }
                        imageCache[post.email!] = image
                    }
                }
            })
        }
    }
    
}
