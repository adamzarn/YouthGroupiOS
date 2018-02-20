//
//  MemberCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

protocol EditMemberCellDelegate: class {
    func toggle(member: Member)
}

class EditMemberCell: UITableViewCell {
        
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    weak var delegate: EditMemberCellDelegate!
    
    var member: Member!
    var leaderBoxChecked: Bool!
    var savedEmail: String!
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var leaderButton: CheckboxButton!
    @IBOutlet weak var nameLabel: UILabel!
        
    func setUp(member: Member) {
        self.member = member
        nameLabel.text = member.name
        if member.leader! {
            leaderButton.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        } else {
            leaderButton.setImage(nil, for: .normal)
        }
        
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
    
    @IBAction func leaderBoxChecked(_ sender: Any) {
        self.delegate.toggle(member: member)
    }
}
