//
//  AccountDetailViewController.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

class AccountDetailViewController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            FirebaseClient.shared.signOut(completion: { success in
                if success {
                    self.appDelegate.userData = nil
                    self.presentLoginView()
                }
            })
        }
        if FBSDKAccessToken.current() != nil {
            FBSDKLoginManager().logOut()
            appDelegate.userData = nil
            presentLoginView()
        }
    }
    
    func presentLoginView() {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.present(loginVC, animated: false, completion: nil)
    }
    
}

//UITableViewDelegate and DataSource
extension AccountDetailViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.userData?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountDetailCell")! as UITableViewCell
        cell.textLabel?.text = appDelegate.userData?[indexPath.row].0
        cell.detailTextLabel?.text = appDelegate.userData?[indexPath.row].1
        return cell
    }
    
}
