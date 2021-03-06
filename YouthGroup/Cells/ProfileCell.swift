//
//  ProfileCell.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/13/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol ProfileCellDelegate: class {
    func didTapProfileImageView(imageData: Data?)
    func didSetProfilePhoto(image: UIImage?)
}

class ProfileCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: CircleImageView!
    @IBOutlet weak var nameLabel: UILabel!
    weak var delegate: ProfileCellDelegate?
    var imageData: Data?
    var cachedImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.isUserInteractionEnabled = false
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ProfileCell.profileImageViewTapped(_:)))
        profileImageView.addGestureRecognizer(recognizer)
    }
    
    @objc func profileImageViewTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didTapProfileImageView(imageData: imageData)
    }
    
    func setUp(image: UIImage?, user: User?) {
        if let user = user {
            nameLabel.text = user.displayName
            cachedImage = imageCache[user.email!]
        }
        if let cachedImage = self.cachedImage {
            profileImageView.isUserInteractionEnabled = true
            profileImageView.image = cachedImage
            self.delegate?.didSetProfilePhoto(image: cachedImage)
        } else if let image = image {
            profileImageView.isUserInteractionEnabled = true
            profileImageView.image = image
            self.delegate?.didSetProfilePhoto(image: image)
        } else {
            profileImageView.image = UIImage(named: "Boy")
            if let user = user, let email = user.email {
                FirebaseClient.shared.getProfilePhoto(email: email, completion: { (data, error) in
                    if let data = data {
                        DispatchQueue.global(qos: .background).async {
                            self.imageData = data
                            let image = UIImage(data: data)
                            self.delegate?.didSetProfilePhoto(image: image)
                            DispatchQueue.main.async {
                                self.profileImageView.isUserInteractionEnabled = true
                                self.profileImageView.image = image
                                imageCache[email] = image
                            }
                        }
                    } else {
                        self.profileImageView.isUserInteractionEnabled = true
                    }
                })
            }
        }
    }
    
}
