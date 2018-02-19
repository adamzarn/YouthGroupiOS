//
//  LessonsViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class LessonsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let verse = "Matthew 1:16-25"
        if let parameters = verse.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            NetworkClient.shared.getBibleVerses(parameters: parameters, completion: { (reference, text, verses) in
                if let reference = reference, let text = text, let verses = verses {
                    print(reference)
                    print(text)
                    for verse in verses {
                        print("\(verse.number) \(verse.text)")
                    }
                }
            })
        }
    }
    
}
