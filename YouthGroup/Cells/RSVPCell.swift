//
//  RSVPCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class RSVPCell: UITableViewCell {
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bringingLabel: UILabel!
    var savedEmail: String!
    
    func setUp(bringer: Bringer) {
        
        nameLabel.text = bringer.name!
        if let bringing = bringer.bringing {
            bringingLabel.isHidden = false
            bringingLabel.text = "Bringing: \(bringing)"
        } else {
            bringingLabel.isHidden = true
        }
        savedEmail = bringer.email!
        
        self.memberImageView.image = UIImage(named: "Boy")
        
        if let image = imageCache[bringer.email!] {
            self.memberImageView.image = image
        } else {
            FirebaseClient.shared.getProfilePhoto(email: bringer.email!, completion: { (data, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        if self.savedEmail == bringer.email! {
                            self.memberImageView.image = image
                        }
                        imageCache[bringer.email!] = image
                    }
                }
            })
        }
        
    }
    
}
