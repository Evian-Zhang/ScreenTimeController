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
    case installedAppTableNotFound
    case deviceStateTableNotFound
    case usageTableNotFound
    case entryNotFound
    case multipleUsers
    case deleteFail
    case changeFail
    case unknown
}

enum STCSearchType {
    case applicationName
    case bundleID
    case domain
}

extension Notification.Name {
    static let STCDatabaseConnectionSuccess = Notification.Name("STCDatabaseConnectionSuccess")
    static let STCScreenTimeQueryStart = Notification.Name("STCScreenTimeQueryStart")
    static let STCScreenTimeDelete = Notification.Name("STCScreenTimeDelete")
    static let STCScreenTimeChange = Notification.Name("STCScreenTimeChange")
}

struct STCTimedItem {
    var z_pk: Int
    var ztotaltimeinseconds: Int
    var zblock: Int
    var zcategory: Int
    var zstartdate: Date
    
    func compare(other: STCTimedItem) -> ComparisonResult {
        return self.zstartdate.compare(other.zstartdate)
    }
}
