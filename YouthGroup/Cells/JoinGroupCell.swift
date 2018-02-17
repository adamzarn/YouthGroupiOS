//
//  JoinGroupCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class JoinGroupCell: UITableViewCell {
    
    @IBOutlet weak var churchLabel: UILabel!
    @IBOutlet weak var createdByLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func setUp(group: Group) {
        churchLabel.text = group.church
        createdByLabel.text = "Created by: " + group.createdBy
        nicknameLabel.text = group.nickname
        if let description = group.description {
            if description.isEmpty {
                descriptionLabel.isHidden = true
            } else {
                descriptionLabel.isHidden = false
                descriptionLabel.text = description
            }
        }
    }
    
}
