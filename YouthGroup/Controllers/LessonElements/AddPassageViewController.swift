//
//  AddPassageViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/22/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class AddPassageViewController: UIViewController {
    
    @IBOutlet weak var referenceTextField: UITextField!
    @IBOutlet weak var versesTextView: UITextView!
    @IBOutlet weak var aiv: UIActivityIndicatorView!
    
    var groupUID: String!
    var lesson: Lesson!
    var passageToEdit: Passage?
    var reference: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Aiv.hide(aiv: aiv)
        if let passage = passageToEdit {
            referenceTextField.text = passage.reference
            versesTextView.text = passage.text
            title = "Edit Passage"
        } else {
            referenceTextField.text = ""
            versesTextView.text = ""
            title = "Add Passage"
        }
    }
    
    @IBAction func referenceChanged(_ sender: Any) {
        let reference = referenceTextField.text
        if let parameters = reference?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            NetworkClient.shared.getBibleVerses(parameters: parameters, completion: { (reference, text, verses) in
                if let reference = reference, let verses = verses {
                    self.reference = reference
                    var versesCopy = verses
                    var lastVerse = 0
                    var startingVerse = 0
                    var reference = ""
                    var text = ""
                    var finalText = NSMutableAttributedString()
                    let boldAttributes = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 14)]
                    let sizeAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14)]
                    
                    finalText = NSMutableAttributedString(attributedString: NSAttributedString(string: ""))
                    while versesCopy.count > 0 {
                        
                        let verseText = versesCopy.first!.text.replacingOccurrences(of: "\n", with: "")
                        if lastVerse == 0 {
                            
                            reference = String(versesCopy.first!.number)
                            text = verseText
                            startingVerse = versesCopy.first!.number
                            
                        } else if versesCopy.first!.number == lastVerse + 1 {
                            
                            reference = "\(startingVerse)-\(versesCopy.first!.number)"
                            text = "\(text) \(verseText)"
                            
                        } else if versesCopy.first!.number != lastVerse + 1 {
                            
                            let attributedReference = NSAttributedString(string: reference, attributes: boldAttributes)
                            let attributedText = NSAttributedString(string: " \(text)\n\n", attributes: sizeAttributes)
                            finalText.append(attributedReference)
                            finalText.append(attributedText)
                            
                            reference = String(versesCopy.first!.number)
                            text = verseText
                            startingVerse = versesCopy.first!.number
                            
                        }
                        
                        lastVerse = versesCopy.first!.number
                        versesCopy.removeFirst()
                        
                    }
                    
                    let attributedReference = NSMutableAttributedString(string: reference, attributes: boldAttributes)
                    let attributedText = NSAttributedString(string: " \(text)", attributes: sizeAttributes)
                    finalText.append(attributedReference)
                    finalText.append(attributedText)
                    
                    DispatchQueue.main.async {
                        self.versesTextView.attributedText = finalText
                    }
                    
                } else {
                    self.reference = nil
                    DispatchQueue.main.async {
                        self.versesTextView.text = ""
                    }
                }
            })
        }
    }
    
    func verifyPassage() throws {
        let reference = self.reference
        let text = versesTextView.text!
        
        if reference == nil {
            throw AddPassageError.missingReference
        }
        if text.isEmpty {
            throw AddPassageError.missingText
        }
        
        var passage: Passage!
        if let passageToEdit = passageToEdit {
            passage = Passage(uid: passageToEdit.uid, position: passageToEdit.position, type: passageToEdit.type, reference: reference!, text: text)
        } else {
            let position = (lesson.elements != nil) ? (lesson.elements?.count)! : 0
            passage = Passage(uid: nil, position: position, type: Elements.passage.rawValue, reference: reference!, text: text)
        }
        
        FirebaseClient.shared.pushElement(groupUID: groupUID, lessonUID: lesson.uid!, element: passage, completion: { (error, successMessage) in
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
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        Aiv.show(aiv: aiv)
        do {
            try verifyPassage()
        } catch AddPassageError.missingReference {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingReference"), message: Helper.getString(key: "missingReferenceMessage"), vc: self)
        } catch AddPassageError.missingText {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "missingText"), message: Helper.getString(key: "missingTextMessage"), vc: self)
        } catch {
            Aiv.hide(aiv: aiv)
            Alert.showBasic(title: Helper.getString(key: "error"), message: Helper.getString(key: "ue_m"), vc: self)
        }
        
    }
    
}

extension AddPassageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
