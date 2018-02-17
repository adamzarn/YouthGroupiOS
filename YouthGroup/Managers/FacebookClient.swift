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
    
    func getFBUserProfilePhoto(tokenString: String, completion: @escaping (_ data: Data?) -> ()) {
        if let url = URL(string: "https://graph.facebook.com/me/picture?type=large&return_ssl_resources=1&access_token="+tokenString) {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    completion(data)
                } else {
                    completion(nil)
                }
            }.resume()
        }
    }
    
    static let shared = FacebookClient()
    private override init() {
        super.init()
    }

}
