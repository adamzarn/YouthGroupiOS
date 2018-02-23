//
//  AddActivityViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class AddActivityViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var directionsTextView: BorderedTextView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    var groupUID: String!
    var lesson: Lesson!
    var activityToEdit: Activity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selector = #selector(AddActivityViewController.dismissKeyboard)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        directionsTextView.inputAccessoryView = toolbar
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Aiv.hide(aiv: aiv)
        if let activity = activityToEdit {
            nameTextField.text = activity.name
            directionsTextView.text = activity.directions
            title = "Edit Activity"
        } else {
            nameTextField.text = ""
            directionsTextView.text = ""
            title = "Add Activity"
        }
    }
    
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func verifyActivity() throws {
        let name = nameTextField.text!
        let directions = directionsTextView.text!
        
        if name.isEmpty {
            throw AddActivityError.missingName
        }
        if directions.isEmpty {
            throw AddActivityError.missingDirections
        }
        
        var activity: Activity!
        if let activityToEdit = activityToEdit {
            activity = Activity(uid: activityToEdit.uid!, position: activityToEdit.position, type: activityToEdit.type, name: name, directions: directions)
        } else {
            let position = (lesson.elements != nil) ? (lesson.elements?.count)! : 0
            activity = Activity(uid: nil, position: position, type: Elements.activity.rawValue, name: name, directions: directions)
        }
        
        FirebaseClient.shared.pushElement(groupUID: groupUID, lessonUID: lesson.uid!, element: activity, completion: { (error, successMessage) in
            Aiv.hide(aiv: self.aiv)
            if let error = error {
                Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
            } else {
                let completion: (UIAlertAction) -> Void = {_ in
                    self.navigationController?.popViewController(animated: true)
                }
                if let successMessage = successMessage {
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: successMessage, vc: self, completion: completion)
                }
            }
        })
        
    }
    
    @IBAction func submitButtonPressed(sender: Any) {
        Aiv.show(aiv: aiv)
        do {
            try verifyActivity()
        } catch AddActivityError.missingName {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingName"), message: Helper.getString(key: "missingNameMessage"), vc: self)
        } catch AddActivityError.missingDirections {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingDirections"), message: Helper.getString(key: "missingDirectionsMessage"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
    }
    
}

extension AddActivityViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
