//
//  ButtonsCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/21/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

protocol ButtonsCellDelegate: class {
    func didSelectGoing()
    func didSelectMaybe()
    func didSelectNotGoing()
}

enum RSVP {
    case unknown
    case going
    case maybe
    case notGoing
}

class ButtonsCell: UITableViewCell {
    
    @IBOutlet weak var goingButton: YouthGroupButton!
    @IBOutlet weak var maybeButton: YouthGroupButton!
    @IBOutlet weak var notGoingButton: YouthGroupButton!
    var buttons: [UIButton]!
    
    weak var delegate: ButtonsCellDelegate?
    
    func setUp(event: Event) {
        buttons = [goingButton, maybeButton, notGoingButton]
        for button in buttons {
            button.layer.borderColor = Colors.primary.cgColor
        }
        switch getRSVP(event: event) {
        case RSVP.going:
            selectButton(buttonToSelect: goingButton)
        case RSVP.maybe:
            selectButton(buttonToSelect: maybeButton)
        case RSVP.notGoing:
            selectButton(buttonToSelect: notGoingButton)
        default:
            deselectAllButtons()
        }
    }
    
    func selectButton(buttonToSelect: UIButton) {
        for button in buttons {
            if button == buttonToSelect {
                button.isEnabled = false
                button.backgroundColor = Colors.primary
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = Colors.primary.cgColor
            } else {
                button.isEnabled = true
                button.backgroundColor = .white
                button.setTitleColor(Colors.primary, for: .normal)
            }
        }
    }
    
    func deselectAllButtons() {
        for button in buttons {
            button.isEnabled = true
            button.backgroundColor = Colors.primary
        }
    }
    
    func getRSVP(event: Event) -> RSVP {
        if let currentUser = Helper.createMemberFromUser() {
            if let going = event.going {
                if going.contains(where: { $0.email == currentUser.email! }) {
                    return RSVP.going
                }
            }
            if let maybe = event.maybe {
                if maybe.contains(where: { $0.email == currentUser.email! }) {
                    return RSVP.maybe
                }
            }
            if let notGoing = event.notGoing {
                if notGoing.contains(where: { $0.email == currentUser.email! }) {
                    return RSVP.notGoing
                }
            }
        } else {
            return RSVP.unknown
        }
        return RSVP.unknown
    }
    
    @IBAction func goingButtonPressed(sender: Any) {
        delegate?.didSelectGoing()
    }
    
    @IBAction func maybeButtonPressed(sender: Any) {
        delegate?.didSelectMaybe()
    }
    
    @IBAction func notGoingButtonPressed(sender: Any) {
        delegate?.didSelectNotGoing()
    }
    
    
}
