//
//  EventCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class EventCell: UITableViewCell {
    
    @IBOutlet weak var eventNameLabel: UILabel!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func setUp(event: Event, groupUID: String) {
        eventNameLabel.text = event.name
        locationNameLabel.text = event.locationName
        let startTime = Helper.formattedTimestamp(ts: event.startTime, includeDate: false, includeTime: true)
        let endTime = Helper.formattedTimestamp(ts: event.endTime, includeDate: false, includeTime: true)
        timeLabel.text = "\(startTime) - \(endTime)"
        
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
