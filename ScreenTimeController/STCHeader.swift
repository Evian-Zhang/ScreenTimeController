//
//  STCError.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/27.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Foundation

enum STCDataModelError: Error {
    case executableNotExist
    case fileNotExist
    case connectionFail
    case blockTableNotFound
    case categoryTableNotFound
    case timedItemTableNotFound
    case entryNotFound
    case unknown
}

enum STCSearchType {
    case applicationName
    case bundleID
    case domain
}

extension Notification.Name {
    static let STCDatabaseConnectionSuccess = Notification.Name("STCDatabaseConnectionSuccess")
}

struct STCBlock {
    var Z_PK: Int?
    var totalTimeInSecond: Int?
    var startTime: Date?
}
