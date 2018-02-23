//
//  AccountDetailCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class AccountDetailCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    func setUp() {
        titleLabel?.textColor = Colors.darkBlue
    }
    
}
