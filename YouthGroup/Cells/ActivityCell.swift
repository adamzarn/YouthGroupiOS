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
    
    func setUp(activity: Activity) {
        nameLabel.text = activity.name
        directionsLabel.text = activity.directions
        
        backgroundCardView.makeCardView()
        backgroundCardView.backgroundColor = Colors.beige
        
    }
    
}
