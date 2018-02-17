//
//  AddPhotoViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/13/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FBSDKCoreKit

protocol AddPhotoViewControllerDelegate: class {
    func setChosenProfilePhoto(chosenImage: UIImage?)
}

class AddPhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    @IBOutlet weak var choosePhotoButton: YouthGroupButton!
    @IBOutlet weak var useFacebookPhotoButton: YouthGroupButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var skipAddPhotoButton: UIBarButtonItem!
    @IBOutlet weak var instructionLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    var imageData: Data?
    var chosenImage: UIImage?
    var restorationID: String?
    weak var delegate: AddPhotoViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.borderWidth = 1.0
        imageView.layer.borderColor = UIColor.black.cgColor
        
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .overCurrentContext
        
        let imageTapRecognizer = UITapGestureRecognizer()
        imageTapRecognizer.addTarget(self, action: #selector(AddPhotoViewController.imageTapped(recognizer:)))
        imageView.addGestureRecognizer(imageTapRecognizer)
        
        instructionLabel.text = getString(key: "submitPhotoInstructions")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        restorationID = self.navigationController?.restorationIdentifier
        self.navigationItem.hidesBackButton = (restorationID == "LoginNavigationController")
        
        Aiv.hide(aiv: aiv)
        
        useFacebookPhotoButton.isHidden = (FBSDKAccessToken.current() == nil)
        
        choosePhotoButton.setTitle(getString(key: "chooseDifferentPhoto"), for: .normal)
        imageView.image = nil
        if let chosenImage = chosenImage {
            imageView.image = chosenImage
        } else if let imageData = imageData {
            imageView.image = UIImage(data: imageData)
        } else if FBSDKAccessToken.current() != nil {
            setFacebookPhoto()
        } else {
            choosePhotoButton.setTitle(getString(key: "choosePhoto"), for: .normal)
            imageView.image = UIImage(named: "Boy")
        }
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    @objc func imageTapped(recognizer: UITapGestureRecognizer) {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        imagePicked = false
    }
    
    //MARK: IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func setPhotoButtonPressed(_ sender: Any) {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        if imagePicked {
            if let user = Auth.auth().currentUser, let email = user.email, let data = imageData {
                Aiv.show(aiv: aiv)
                FirebaseClient.shared.addProfilePhoto(email: email, data: data, completion: { (error) in
                    Aiv.hide(aiv: self.aiv)
                    if let error = error {
                        Alert.showBasic(title: self.getString(key: "error"), message: error, vc: self)
                    } else {
                        self.chosenImage = UIImage(data: data)
                        self.dismissAddPhoto()
                    }
                })
            }
        } else {
            if restorationID == "LoginNavigationController" {
                Alert.showBasic(title: getString(key: "nps"), message: getString(key: "nps_m"), vc: self)
            } else {
                dismissAddPhoto()
            }

        }
    }
    
    @IBAction func addPhotoLaterButtonPressed(_ sender: Any) {
        goToJoinGroup()
    }
    
    func dismissAddPhoto() {
        if restorationID == "LoginNavigationController" {
            goToJoinGroup()
        } else {
            delegate?.setChosenProfilePhoto(chosenImage: chosenImage)
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func goToJoinGroup() {
        let joinGroupVC = self.storyboard?.instantiateViewController(withIdentifier: "JoinGroupViewController") as! JoinGroupViewController
        joinGroupVC.cancelButton.tintColor = .clear
        joinGroupVC.cancelButton.isEnabled = false
        self.navigationController?.pushViewController(joinGroupVC, animated: true)
    }
    
    @IBAction func useFacebookPhotoPressed(_ sender: Any) {
        if FBSDKAccessToken.current() != nil {
            setFacebookPhoto()
        }
    }
    
    func setFacebookPhoto() {
        let tokenString = FBSDKAccessToken.current().tokenString
        FacebookClient.shared.getFBUserProfilePhoto(tokenString: tokenString!, completion: { (data) in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.imageData = UIImageJPEGRepresentation(image, 0.0)
                    self.imagePicked = true
                    self.useFacebookPhotoButton.isHidden = true
                }
            }
        })
    }
    
    func getString(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
}

extension AddPhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = image
            self.imageData = UIImageJPEGRepresentation(image, 0.25)
            imagePicked = true
        }
        useFacebookPhotoButton.isHidden = (FBSDKAccessToken.current() == nil)
        picker.dismiss(animated: true, completion: nil)
    }
    
}

