//
//  AddPrayerRequestViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol AddPrayerRequestViewControllerDelegate: class {
    func push(prayerRequest: PrayerRequest)
}

class AddPrayerRequestViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var requestTextView: BorderedTextView!
    @IBOutlet weak var anonymousButton: CheckboxButton!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    var checkmarkChecked = false
    
    weak var delegate: AddPrayerRequestViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selector = #selector(AddPrayerRequestViewController.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        requestTextView.inputAccessoryView = toolbar
        
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    @objc func dismissKeyboard() {
        requestTextView.resignFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleTextField.text = ""
        requestTextView.text = ""
        checkmarkChecked = false
        anonymousButton.setImage(nil, for: .normal)
        Aiv.hide(aiv: aiv)
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        Aiv.show(aiv: aiv)
        do {
            try submitPrayerRequest()
        } catch AddPrayerRequestError.missingTitle {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingTitle"), message: Helper.getString(key: "missingTitleMessage"), vc: self)
        } catch AddPrayerRequestError.missingRequest {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingRequest"), message: Helper.getString(key: "missingRequestMessage"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
        
    }
    
    func submitPrayerRequest() throws {
        let title = titleTextField.text!
        let request = requestTextView.text!
        
        if title.isEmpty {
            throw AddPrayerRequestError.missingTitle
        }
        if request.isEmpty {
            throw AddPrayerRequestError.missingRequest
        }
        
        if let user = Auth.auth().currentUser, let name = user.displayName, let email = user.email {
            var prayerRequest = PrayerRequest(uid: nil, submittedBy: name, submittedByEmail: email, timestamp: -1*Int64(Helper.getCurrentDateAndTime())!, title: title, request: request, answered: false, anonymous: checkmarkChecked, prayingMembers: nil)
            if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
                FirebaseClient.shared.addPrayerRequest(prayerRequest: prayerRequest, groupUID: groupUID, completion: { (prayerRequestUID, error) in
                    Aiv.hide(aiv: self.aiv)
                    if let error = error {
                        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                    } else {
                        let completion: (UIAlertAction) -> Void = {_ in
                            prayerRequest.uid = prayerRequestUID!
                            self.delegate?.push(prayerRequest: prayerRequest)
                            self.navigationController?.popViewController(animated: true)
                        }
                        Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: Helper.getString(key: "prayerSubmittedMessage"), vc: self, completion: completion)
                    }
                })
            }
        }
        
    }
    
    @IBAction func checkmarkChecked(_ sender: Any) {
        checkmarkChecked = !checkmarkChecked
        if checkmarkChecked {
            anonymousButton.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        } else {
            anonymousButton.setImage(nil, for: .normal)
        }
    }
}

extension AddPrayerRequestViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
