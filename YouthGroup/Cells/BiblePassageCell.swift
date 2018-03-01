//
//  BiblePassageCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class BiblePassageCell: UITableViewCell {
    
    @IBOutlet weak var backgroundCardView: UIView!
    @IBOutlet weak var referenceLabel: UILabel!
    @IBOutlet weak var versesLabel: UILabel!
    
    func setUp(passage: Passage, groupUID: String, editing: Bool) {
        
        referenceLabel.text = passage.reference
        
        if editing {
            versesLabel.numberOfLines = 1
            versesLabel.minimumScaleFactor = 1.0
            versesLabel.text = ""
        } else {
            versesLabel.numberOfLines = 0
            versesLabel.minimumScaleFactor = 0.5
            versesLabel.text = passage.text
        }
        
        backgroundCardView.makeCardView()
        backgroundCardView.backgroundColor = Colors.lightBlue
        
    }
    
}
