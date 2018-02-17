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

class AddPrayerRequestViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var requestTextView: UITextView!
    @IBOutlet weak var anonymousButton: CheckboxButton!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    var checkmarkChecked = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.barStyle = .default
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(AddPrayerRequestViewController.dismissKeyboard))
        toolbar.items = [flex, done]
        
        requestTextView.layer.borderColor = UIColor.lightGray.cgColor
        requestTextView.layer.borderWidth = 0.5
        requestTextView.layer.cornerRadius = 4.0
        
        requestTextView.inputAccessoryView = toolbar
        
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
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
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
            let prayerRequest = PrayerRequest(uid: nil, submittedBy: name, submittedByEmail: email, timestamp: Helper.getCurrentDateAndTime(), title: title, request: request, answered: false, anonymous: checkmarkChecked)
            if let groupUID = UserDefaults.standard.string(forKey: "currentGroup") {
                FirebaseClient.shared.addPrayerRequest(prayerRequest: prayerRequest, groupUID: groupUID, completion: { (error) in
                    Aiv.hide(aiv: self.aiv)
                    if let error = error {
                        Alert.showBasic(title: "Error", message: error, vc: self)
                    } else {
                        let completion: (UIAlertAction) -> Void = {_ in
                            UserDefaults.standard.setValue(Tabs.prayerRequests.rawValue, forKey: "tabToDisplay")
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        }
                        Alert.showBasicWithCompletion(title: "Success", message: "Your prayer was successfully added.", vc: self, completion: completion)
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
