//
//  PrayerRequestCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

var imageCache = [String: UIImage]()

class PrayerRequestCell: UITableViewCell {
    
    @IBOutlet weak var prayerRequestImageView: CircleImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var answeredButton: CheckboxButton!
    
    var savedEmail: String!
    
    func setUp(request: PrayerRequest) {
        
        savedEmail = request.submittedByEmail
        setCheckmark(answered: request.answered)
        
        self.prayerRequestImageView.image = UIImage(named: "Boy")
        
        titleLabel.text = request.title
        timestampLabel.text = Helper.formattedTimestamp(ts: request.timestamp, includeDate: true, includeTime: true)
        
        if request.anonymous {
            nameLabel.text = Helper.getString(key: "anonymous")
        } else {
            nameLabel.text = request.submittedBy
            if let image = imageCache[request.submittedByEmail] {
                self.prayerRequestImageView.image = image
            } else {
                FirebaseClient.shared.getProfilePhoto(email: request.submittedByEmail, completion: { (data, error) in
                    if let data = data {
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            if self.savedEmail == request.submittedByEmail {
                                self.prayerRequestImageView.image = image
                            }
                            imageCache[request.submittedByEmail] = image
                        }
                   }
                })
            }
        }
        
    }
    
    func setCheckmark(answered: Bool) {
        if answered {
            answeredButton.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        } else {
            answeredButton.setImage(nil, for: .normal)
        }
    }
    
}
