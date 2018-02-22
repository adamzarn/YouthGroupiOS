//
//  BiblePassageCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class BiblePassageCell: UITableViewCell {
    
    @IBOutlet weak var backgroundCardView: UIView!
    @IBOutlet weak var referenceLabel: UILabel!
    @IBOutlet weak var versesLabel: UILabel!
    
    func setUp(passage: Passage) {
        
        referenceLabel.text = passage.reference
        versesLabel.text = passage.text
        
        backgroundCardView.backgroundColor = .white
        contentView.backgroundColor = UIColor.lightGray
        
        backgroundCardView.layer.cornerRadius = 5.0
        backgroundCardView.layer.masksToBounds = false
        
        backgroundCardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        backgroundCardView.layer.shadowOffset = CGSize(width: 0, height: 0)
        backgroundCardView.layer.shadowOpacity = 0.8
        
    }
    
}
