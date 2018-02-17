//
//  MemberCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class MemberCell: UITableViewCell {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var savedEmail: String!
    
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        memberImageView.layer.borderColor = UIColor.black.cgColor
        memberImageView.layer.borderWidth = 0.5
    }
    
    func setUp(member: Member) {
        nameLabel.text = member.name
        savedEmail = member.email!
        
        self.memberImageView.image = UIImage(named: "Boy")
        
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
