//
//  LessonCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class LessonCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var leadersLabel: UILabel!
    
    func setUp(lesson: Lesson, groupUID: String) {
        titleLabel.text = lesson.title
        let leadersString = lesson.leaders.map { $0.name }.joined(separator: ", ")
        if lesson.leaders.count > 1 {
            leadersLabel.text = "Leaders: \(leadersString)"
        } else {
            leadersLabel.text = "Leader: \(leadersString)"
        }
        
        if let email = Auth.auth().currentUser?.email {
            FirebaseClient.shared.isLeader(groupUID: groupUID, email: email, completion: { (isLeader, error) in
                if isLeader {
                    self.accessoryType = .detailDisclosureButton
                } else {
                    self.accessoryType = .none
                }
            })
        }
        
    }
    
}
