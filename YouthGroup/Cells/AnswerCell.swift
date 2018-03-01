//
//  AnswerCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/24/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class AnswerCell: UITableViewCell {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var savedEmail: String!
    
    @IBOutlet weak var memberImageView: CircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    func setUp(answerer: Answerer) {
        
        nameLabel.text = answerer.name
        answerLabel.text = answerer.answer
        timestampLabel.text = Helper.formattedTimestamp(ts: String(answerer.timestamp), includeDate: true, includeTime: true)
        
        savedEmail = answerer.email!
        self.memberImageView.image = UIImage(named: "Boy")
        
        if let image = imageCache[answerer.email!] {
            self.memberImageView.image = image
        } else {
            FirebaseClient.shared.getProfilePhoto(email: answerer.email!, completion: { (data, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        if self.savedEmail == answerer.email! {
                            self.memberImageView.image = image
                        }
                        imageCache[answerer.email!] = image
                    }
                }
            })
        }
    }
    
}
