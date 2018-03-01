//
//  ActivityCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class ActivityCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var directionsLabel: UILabel!
    @IBOutlet weak var backgroundCardView: UIView!
    
    func setUp(activity: Activity, editing: Bool) {
        nameLabel.text = activity.name
        
        if editing {
            nameLabel.numberOfLines = 1
            nameLabel.minimumScaleFactor = 1.0
            directionsLabel.text = ""
        } else {
            nameLabel.numberOfLines = 0
            nameLabel.minimumScaleFactor = 0.5
            directionsLabel.text = activity.directions
        }
        
        backgroundCardView.makeCardView()
        backgroundCardView.backgroundColor = Colors.beige
        
    }
    
}
