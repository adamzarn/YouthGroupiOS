//
//  ButtonCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/15/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

protocol ButtonCellDelegate: class {
    func didSelectButton(buttonType: ButtonType)
}

enum ButtonType {
    case join
    case create
}

class ButtonCell: UITableViewCell {
    
    @IBOutlet weak var button: YouthGroupButton!
    weak var delegate: ButtonCellDelegate?
    var buttonType: ButtonType!
    
    func setUp(title: String, buttonType: ButtonType) {
        button.setTitle(title, for: .normal)
        self.buttonType = buttonType
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        delegate?.didSelectButton(buttonType: buttonType)
    }

}
