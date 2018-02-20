//
//  CreateEventViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class CreateEventViewController: UIViewController {
    
    var eventToEdit: Event?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if eventToEdit != nil {
            title = "Edit Event"
        } else {
            title = "Create Event"
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
