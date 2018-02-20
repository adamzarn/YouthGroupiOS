//
//  EventViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class EventViewController: UIViewController {
    
    var event: Event!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = event.name
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
