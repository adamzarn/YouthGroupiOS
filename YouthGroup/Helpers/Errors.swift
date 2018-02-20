//
//  Errors.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/15/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation

enum CreateAccountError: Error {
    case missingFirstName
    case missingLastName
    case missingEmail
    case missingPassword
    case passwordMismatch
}

enum LoginError: Error {
    case missingEmail
    case missingPassword
}

enum CreateGroupError: Error {
    case missingChurch
    case missingNickname
    case missingPassword
}

enum AddPrayerRequestError: Error {
    case missingTitle
    case missingRequest
}

enum CreateEventError: Error {
    case missingName
    case missingDate
    case missingStartTime
    case missingEndTime
    case invalidEndTime
    case missingLocationName
    case missingStreet
    case missingCity
    case missingState
    case missingZip
}
