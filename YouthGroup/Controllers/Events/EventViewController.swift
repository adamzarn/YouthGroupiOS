//
//  EventViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/19/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

enum EventSections: Int {
    case date = 0
    case location = 1
    case address = 2
    case notes = 3
    case buttons = 4
    case going = 5
    case maybe = 6
    case notGoing = 7
}

class EventViewController: UIViewController {
    
    var groupUID: String!
    var event: Event!
    let infoSections = ["WHEN", "WHERE", "ADDRESS", "NOTES", "Buttons", "GOING", "MAYBE", "NOT GOING"]
    
    @IBOutlet weak var infoTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.infoTableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = event.name
    }
    
}

extension EventViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section > EventSections.buttons.rawValue {
            if let email = Auth.auth().currentUser?.email {
                switch indexPath.section {
                case EventSections.going.rawValue:
                    let rsvp = event.going![indexPath.row]
                    if rsvp.email == email {
                        return true
                    }
                case EventSections.maybe.rawValue:
                    let rsvp = event.maybe![indexPath.row]
                    if rsvp.email == email {
                        return true
                    }
                case EventSections.notGoing.rawValue:
                    let rsvp = event.notGoing![indexPath.row]
                    if rsvp.email == email {
                        return true
                    }
                default:
                    return false
                }
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch indexPath.section {
            case EventSections.going.rawValue:
                let rsvp = event.going![indexPath.row]
                event.going!.remove(at: indexPath.row)
                FirebaseClient.shared.deleteRSVP(groupUID: groupUID, eventUID: event.uid!, rsvp: "going", email: rsvp.email, completion: { error in })
            case EventSections.maybe.rawValue:
                let rsvp = event.maybe![indexPath.row]
                event.maybe!.remove(at: indexPath.row)
                FirebaseClient.shared.deleteRSVP(groupUID: groupUID, eventUID: event.uid!, rsvp: "maybe", email: rsvp.email, completion: { error in })
            case EventSections.notGoing.rawValue:
                let rsvp = event.notGoing![indexPath.row]
                event.notGoing!.remove(at: indexPath.row)
                FirebaseClient.shared.deleteRSVP(groupUID: groupUID, eventUID: event.uid!, rsvp: "notGoing", email: rsvp.email, completion: { error in })
            default:
                ()
            }
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section >= EventSections.notes.rawValue {
            switch section {
            case EventSections.notes.rawValue:
                if event.notes == "" {
                    return nil
                }
            case EventSections.buttons.rawValue:
                return nil
            case EventSections.going.rawValue:
                if event.going == nil || event.going?.count == 0 {
                    return nil
                }
            case EventSections.maybe.rawValue:
                if event.maybe == nil || event.maybe?.count == 0 {
                    return nil
                }
            case EventSections.notGoing.rawValue:
                if event.notGoing == nil || event.notGoing?.count == 0 {
                    return nil
                }
            default:
                return nil
            }
        }
        return infoSections[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return infoSections.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > EventSections.buttons.rawValue {
            return 60.0
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case EventSections.notes.rawValue:
            if event.notes == "" {
                return 0
            } else {
                return 1
            }
        case EventSections.going.rawValue:
            return event.going?.count ?? 0
        case EventSections.maybe.rawValue:
            return event.maybe?.count ?? 0
        case EventSections.notGoing.rawValue:
            return event.notGoing?.count ?? 0
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        case EventSections.date.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
            cell.selectionStyle = .none
            let date = Helper.formattedDate(ts: event.date)
            let startTime = Helper.formattedTime(ts: event.startTime)
            let endTime = Helper.formattedTime(ts: event.endTime)
            cell.textLabel?.text = "\(date) \(startTime) - \(endTime)"
            return cell
            
        case EventSections.location.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
            cell.selectionStyle = .none
            cell.textLabel?.text = event.locationName
            return cell
            
        case EventSections.address.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
            cell.selectionStyle = .default
            let street = event.address.street
            let city = event.address.city
            let state = event.address.state
            let zip = event.address.zip
            cell.textLabel?.text = "\(street), \(city), \(state) \(zip)"
            return cell
            
        case EventSections.notes.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell")! as UITableViewCell
            cell.selectionStyle = .none
            cell.textLabel?.text = event.notes ?? "No Notes"
            return cell
            
        case EventSections.buttons.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonsCell") as! ButtonsCell
            cell.selectionStyle = .none
            cell.delegate = self
            cell.setUp(event: event)
            return cell
            
        case EventSections.going.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rsvpCell") as! RSVPCell
            let bringer = event.going?[indexPath.row]
            cell.setUp(bringer: bringer!)
            return cell
            
        case EventSections.maybe.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rsvpCell") as! RSVPCell
            let bringer = event.maybe?[indexPath.row]
            cell.setUp(bringer: bringer!)
            return cell
            
        case EventSections.notGoing.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rsvpCell") as! RSVPCell
            let bringer = event.notGoing?[indexPath.row]
            cell.setUp(bringer: bringer!)
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == EventSections.address.rawValue {
            let cell = tableView.cellForRow(at: indexPath)
            if let addressString = cell?.textLabel?.text {
                goToMaps(addressString: addressString)
            }
        }
    }
    
    func goToMaps(addressString: String) {
        
        let formattedAddressString = addressString.replacingOccurrences(of: " ", with: "+")
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        if let googleMapsURL = URL(string:"comgooglemaps://") {
            if UIApplication.shared.canOpenURL(googleMapsURL) {
                actionSheet.addAction(UIAlertAction(title: Helper.getString(key: "googleMaps"), style: UIAlertActionStyle.default, handler: { (action) in
                    if let url = URL(string: "comgooglemaps://?saddr=&daddr=\(formattedAddressString)&directionsmode=driving") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
            }
        }
        
        actionSheet.addAction(UIAlertAction(title: Helper.getString(key: "appleMaps"), style: UIAlertActionStyle.default, handler: { (action) in
            if let url = URL(string: "http://maps.apple.com/maps?saddr=&daddr=\(formattedAddressString)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: Helper.getString(key: "cancel"), style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
}

extension EventViewController: ButtonsCellDelegate {
    
    func didSelectGoing() {
        let alertController = UIAlertController(title: Helper.getString(key: "bringing"), message: nil, preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: Helper.getString(key: "submit"), style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                self.addBringer(rsvp: RSVP.going, bringing: field.text!)
            }
        }
        
        let cancelAction = UIAlertAction(title: Helper.getString(key: "nothing"), style: .cancel) { (_) in
            self.addBringer(rsvp: RSVP.going, bringing: nil)
        }
        
        alertController.addTextField { (textField) in
            textField.textAlignment = .center
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func didSelectMaybe() {
        addBringer(rsvp: RSVP.maybe, bringing: nil)
    }
    
    func didSelectNotGoing() {
        addBringer(rsvp: RSVP.notGoing, bringing: nil)
    }
    
    func addBringer(rsvp: RSVP, bringing: String?) {
        if let member = Helper.createMemberFromUser() {
            let bringer = Bringer(email: member.email, name: member.name, leader: nil, bringing: bringing)
            switch rsvp {
            case .going:
                FirebaseClient.shared.updateRSVP(groupUID: groupUID, eventUID: event.uid!, rsvp: "going", bringer: bringer, completion: { (error) in
                    if let error = error {
                        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                    } else {
                        self.updateGoing(bringer: bringer)
                    }
                })
            case .maybe:
                FirebaseClient.shared.updateRSVP(groupUID: groupUID, eventUID: event.uid!, rsvp: "maybe", bringer: bringer, completion: { (error) in
                    if let error = error {
                        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                    } else {
                        self.updateMaybe(bringer: bringer)
                    }
                })
            case .notGoing:
                FirebaseClient.shared.updateRSVP(groupUID: groupUID, eventUID: event.uid!, rsvp: "notGoing", bringer: bringer, completion: { (error) in
                    if let error = error {
                        Alert.showBasic(title: Helper.getString(key: "error"), message: error, vc: self)
                    } else {
                        self.updateNotGoing(bringer: bringer)
                    }
                })
            default:
                ()
            }
        }
    }
    
    func updateGoing(bringer: Bringer) {
        if event.going != nil {
            event.going!.append(bringer)
        } else {
            event.going = [bringer]
        }
        event.going?.sort(by: {$0.name < $1.name })
        event.maybe = event.maybe?.filter { $0.email != bringer.email }
        event.notGoing = event.notGoing?.filter { $0.email != bringer.email }
        
        let indexSet = IndexSet(EventSections.buttons.rawValue...EventSections.notGoing.rawValue)
        self.infoTableView.reloadSections(indexSet, with: .automatic)
    }
    
    func updateMaybe(bringer: Bringer) {
        if event.maybe != nil {
            event.maybe!.append(bringer)
        } else {
            event.maybe = [bringer]
        }
        event.maybe?.sort(by: {$0.name < $1.name })
        event.going = event.going?.filter { $0.email != bringer.email }
        event.notGoing = event.notGoing?.filter { $0.email != bringer.email }
        
        let indexSet = IndexSet(EventSections.buttons.rawValue...EventSections.notGoing.rawValue)
        self.infoTableView.reloadSections(indexSet, with: .automatic)
    }
    
    func updateNotGoing(bringer: Bringer) {
        if event.notGoing != nil {
            event.notGoing!.append(bringer)
        } else {
            event.notGoing = [bringer]
        }
        event.notGoing?.sort(by: {$0.name < $1.name })
        event.going = event.going?.filter { $0.email != bringer.email }
        event.maybe = event.maybe?.filter { $0.email != bringer.email }
        
        let indexSet = IndexSet(EventSections.buttons.rawValue...EventSections.notGoing.rawValue)
        self.infoTableView.reloadSections(indexSet, with: .automatic)
    }
    
}
