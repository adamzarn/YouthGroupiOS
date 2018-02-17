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
    }
    
    @IBAction func leaderBoxChecked(_ sender: Any) {
        self.delegate.toggle(member: member)
    }
}
