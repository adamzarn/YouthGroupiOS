//
//  FacebookClient.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/8/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import FBSDKCoreKit

class FacebookClient: NSObject {
    
    func getFBUserEmail(completion: @escaping (_ email: String?) -> ()) {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields" : "email"])
            .start(completionHandler:  { (connection, result, error) in
            if let result = result {
                let result = result as! NSDictionary
                let email = result.value(forKey: "email") as? String
                completion(email)
            } else {
                completion(nil)
            }
        })
    }
    
    static let shared = FacebookClient()
    private override init() {
        super.init()
    }

}
