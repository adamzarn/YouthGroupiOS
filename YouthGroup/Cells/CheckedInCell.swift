//
//  CheckedInCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/24/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class CheckedInCell: UICollectionViewCell {
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    var savedEmail: String!
    
    func setUp(member: Member) {
        nameLabel.text = member.name.components(separatedBy: " ")[0]
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
