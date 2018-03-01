//
//  Constants.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/16/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

struct NotificationKeys {
    static let reloadAccount = "reloadAccount"
}
struct States {
    static let options = ["State", "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL","IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT","NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI","SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
}

struct QueryLimits {
    static let posts: UInt = 21
    static let prayerRequests: UInt = 21
    static let events: UInt = 21
}

struct Constants {
    static let threshold = CGFloat(10.0)
}
