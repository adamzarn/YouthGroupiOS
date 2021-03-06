//
//  CreateEventViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

protocol CreateEventViewControllerDelegate: class {
    func push(event: Event, groupUID: String)
    func edit(event: Event, indexPath: IndexPath)
    func displayError(error: String)
}

class CreateEventViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var startTimeTextField: UITextField!
    @IBOutlet weak var endTimeTextField: UITextField!
    @IBOutlet weak var locationNameTextField: UITextField!
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    @IBOutlet weak var notesTextView: BorderedTextView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    weak var delegate: CreateEventViewControllerDelegate?
    
    var keyboardMovers: [Any]!
    
    let datePicker = UIDatePicker()
    let startTimePicker = UIDatePicker()
    let endTimePicker = UIDatePicker()
    
    var dateToSubmit: String?
    var startTimeToSubmit: String?
    var endTimeToSubmit: String?
    
    let statePicker = UIPickerView()
    let stateOptions = States.options
    
    var groupUID: String!
    var eventToEdit: Event?

    var indexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.datePickerMode = .date
        startTimePicker.datePickerMode = .time
        endTimePicker.datePickerMode = .time
        
        dateTextField.inputView = datePicker
        startTimeTextField.inputView = startTimePicker
        endTimeTextField.inputView = endTimePicker
        
        let selector = #selector(CreateEventViewController.dismissPicker)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: selector)
        let toolbar = Toolbar.getDoneToolbar(done: done)
        dateTextField.inputAccessoryView = toolbar
        startTimeTextField.inputAccessoryView = toolbar
        endTimeTextField.inputAccessoryView = toolbar
        notesTextView.inputAccessoryView = toolbar
        
        datePicker.addTarget(self, action: #selector(CreateEventViewController.setDateAndTime(sender:)), for: .valueChanged)
        startTimePicker.addTarget(self, action: #selector(CreateEventViewController.setDateAndTime(sender:)), for: .valueChanged)
        endTimePicker.addTarget(self, action: #selector(CreateEventViewController.setDateAndTime(sender:)), for: .valueChanged)
        
        keyboardMovers = [locationNameTextField, streetTextField, cityTextField, stateTextField, zipTextField, notesTextView]
        
        statePicker.delegate = self
        statePicker.dataSource = self
        stateTextField.inputView = statePicker
        stateTextField.inputAccessoryView = toolbar
        zipTextField.inputAccessoryView = toolbar
        
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    @objc func setDateAndTime(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmssSSS"
        
        let dateText = dateFormatter.string(from: sender.date)
        let timeText = timeFormatter.string(from: sender.date)
        
        if dateTextField.isFirstResponder {
            dateToSubmit = dateText
            dateTextField.text = Helper.formattedDate(ts: dateText)
        } else if startTimeTextField.isFirstResponder {
            startTimeToSubmit = timeText
            startTimeTextField.text = Helper.formattedTime(ts: timeText)
        } else if endTimeTextField.isFirstResponder {
            endTimeToSubmit = timeText
            endTimeTextField.text = Helper.formattedTime(ts: timeText)
        }
    }
    
    func keyboardMoverIsFirstResponder() -> Bool {
        for item in keyboardMovers {
            if item is UITextField {
                if (item as! UITextField).isFirstResponder {
                    return true
                }
            }
            if item is UITextView {
                if (item as! UITextView).isFirstResponder {
                    return true
                }
            }
        }
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Aiv.hide(aiv: aiv)
        KeyboardNotifications.subscribe(vc: self, showSelector: #selector(CreateEventViewController.keyboardWillShow), hideSelector: #selector(CreateEventViewController.keyboardWillHide))
        if let event = eventToEdit {
            title = "Edit Event"
            nameTextField.text = event.name
            dateTextField.text = Helper.formattedDate(ts: event.date)
            startTimeTextField.text = Helper.formattedTime(ts: event.startTime)
            endTimeTextField.text = Helper.formattedTime(ts: event.endTime)
            locationNameTextField.text = event.locationName
            streetTextField.text = event.address.street
            cityTextField.text = event.address.city
            stateTextField.text = event.address.state
            zipTextField.text = event.address.zip
            if let notes = event.notes {
                notesTextView.text = notes
            }
        } else {
            title = "Create Event"
            for subview in self.view.subviews {
                if subview is UITextField {
                    (subview as! UITextField).text = ""
                }
                if subview is UITextView {
                    (subview as! UITextView).text = ""
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        KeyboardNotifications.unsubscribe(vc: self)
    }
    
    @objc func dismissPicker() {
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let keyboardHeight = KeyboardNotifications.getKeyboardHeight(notification: notification)
        if keyboardMoverIsFirstResponder() {
            view.frame.origin.y = -keyboardHeight
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        view.frame.origin.y = 0
    }
    
    func verifyEvent() throws {
        let name = nameTextField.text!
        let date = dateTextField.text!
        let startTime = startTimeTextField.text!
        let endTime = endTimeTextField.text!
        let locationName = locationNameTextField.text!
        let street = streetTextField.text!
        let city = cityTextField.text!
        let state = stateTextField.text!
        let zip = zipTextField.text!
        let notes = notesTextView.text!
        
        if name.isEmpty {
            throw CreateEventError.missingName
        }
        if date.isEmpty {
            throw CreateEventError.missingDate
        }
        if startTime.isEmpty {
            throw CreateEventError.missingStartTime
        }
        if startTimePicker.date > endTimePicker.date {
            throw CreateEventError.invalidEndTime
        }
        if endTime.isEmpty {
            throw CreateEventError.missingEndTime
        }
        if locationName.isEmpty {
            throw CreateEventError.missingLocationName
        }
        if street.isEmpty {
            throw CreateEventError.missingStreet
        }
        if state.isEmpty {
            throw CreateEventError.missingState
        }
        if zip.isEmpty {
            throw CreateEventError.missingZip
        }
        
        var finalDate: String
        var finalStartTime: String
        var finalEndTime: String
        
        if let dateToSubmit = dateToSubmit {
            finalDate = dateToSubmit
        } else {
            finalDate = (eventToEdit?.date)!
        }
        if let startTimeToSubmit = startTimeToSubmit {
            finalStartTime = startTimeToSubmit
        } else {
            finalStartTime = (eventToEdit?.startTime)!
        }
        if let endTimeToSubmit = endTimeToSubmit {
            finalEndTime = endTimeToSubmit
        } else {
            finalEndTime = (eventToEdit?.endTime)!
        }
        
        Aiv.show(aiv: aiv)
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
        
        let address = Address(street: street, city: city, state: state, zip: zip)
        
        let event = Event(uid: nil, name: name, date: finalDate, startTime: finalStartTime, endTime: finalEndTime, locationName: locationName, address: address, notes: notes, going: nil, maybe: nil, notGoing: nil)
        
        if let eventToEdit = eventToEdit, let indexPath = indexPath {
            event.uid = eventToEdit.uid
            event.going = eventToEdit.going
            event.maybe = eventToEdit.maybe
            event.notGoing = eventToEdit.notGoing
            FirebaseClient.shared.editEvent(groupUID: groupUID, event: event, completion: { (error) in
                Aiv.hide(aiv: self.aiv)
                if let error = error {
                    Alert.showBasic(title: Helper.getString(key: "Error"), message: error, vc: self)
                } else {
                    let completion: (UIAlertAction) -> Void = {_ in
                        self.delegate?.edit(event: event, indexPath: indexPath)
                        self.navigationController?.popViewController(animated: true)
                    }
                    Alert.showBasicWithCompletion(title: Helper.getString(key: "success"), message: Helper.getString(key: "editedEventMessage"), vc: self, completion: completion)
                }
            })
        } else {
            FirebaseClient.shared.doesRefExist(node: "Events", uid: groupUID, completion: { exists in
                FirebaseClient.shared.createEvent(event: event, groupUID: self.groupUID, completion: { (eventUID, error) in
                    Aiv.hide(aiv: self.aiv)
                    if let error = error {
                        self.delegate?.displayError(error: error)
                    } else {
                        if !exists {
                            event.uid = eventUID
                            self.delegate?.push(event: event, groupUID: self.groupUID)
                        }
                    }
                    self.navigationController?.popViewController(animated: true)
                })
            })
        }
        
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        do {
            try verifyEvent()
        } catch CreateEventError.missingName {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingName"), message: Helper.getString(key: "missingNameMessage"), vc: self)
        } catch CreateEventError.missingDate {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingDate"), message: Helper.getString(key: "missingDateMessage"), vc: self)
        } catch CreateEventError.missingStartTime {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingStartTime"), message: Helper.getString(key: "missingStartTimeMessage"), vc: self)
        } catch CreateEventError.missingEndTime {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingEndTime"), message: Helper.getString(key: "missingEndTimeMessage"), vc: self)
        } catch CreateEventError.invalidEndTime {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "invalidEndTime"), message: Helper.getString(key: "invalidEndTimeMessage"), vc: self)
        } catch CreateEventError.missingLocationName {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingLocationName"), message: Helper.getString(key: "missingLocationNameMessage"), vc: self)
        } catch CreateEventError.missingStreet {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingStreet"), message: Helper.getString(key: "missingStreetMessage"), vc: self)
        } catch CreateEventError.missingCity {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingCity"), message: Helper.getString(key: "missingCityMessage"), vc: self)
        } catch CreateEventError.missingState {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingState"), message: Helper.getString(key: "missingStateMessage"), vc: self)
        } catch CreateEventError.missingZip {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingZip"), message: Helper.getString(key: "missingZipMessage"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
        
    }
    
}

extension CreateEventViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CreateEventViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stateOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stateOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            stateTextField.text = ""
        } else {
            stateTextField.text = stateOptions[row]
        }
    }
    
}
