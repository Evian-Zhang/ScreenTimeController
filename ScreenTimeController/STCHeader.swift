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
    case countedItemTableNotFound
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

enum STCDisplayUnit {
    case hour
    case day
    case week
    case month
    case year
}

extension Notification.Name {
    static let STCDatabaseConnectionSuccess = Notification.Name("STCDatabaseConnectionSuccess")
    static let STCScreenTimeQueryStart = Notification.Name("STCScreenTimeQueryStart")
    static let STCScreenTimeDelete = Notification.Name("STCScreenTimeDelete")
    static let STCScreenTimeChange = Notification.Name("STCScreenTimeChange")
    static let STCCountedItemQueryStart = Notification.Name("STCCountedItemQueryStart")
    static let STCCountedItemDelete = Notification.Name("STCCountedItemDelete")
    static let STCCountedItemChange = Notification.Name("STCCountedItemChange")
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

struct STCCountedItem {
    var z_pk: Int
    var znumberofnotifications: Int
    var znumberofpickups: Int
    var zblock: Int
    var zstartdate: Date
    
    func compare(other: STCCountedItem) -> ComparisonResult {
        return self.zstartdate.compare(other.zstartdate)
    }
}

class STCTimeUnit {
    var hour = 0
    var minute = 0
    var second = 0
    
    func addSecond(second: Int) -> STCTimeUnit {
        self.second += second
        if self.second >= 60 {
            self.minute += self.second / 60
            self.second = self.second % 60
        }
        if self.minute >= 60 {
            self.hour += self.minute / 60
            self.minute = self.minute % 60
        }
        return self
    }
    
    func doubleValue() -> Double {
        return Double(self.hour) * 60 + Double(self.minute) +  Double(self.second) / 60
    }
    
    func stringValue() -> String {
        var description = ""
        if self.hour > 0 {
            description += NSLocalizedString(String(format: "%dh", self.hour), comment: "")
        }
        if !((self.hour == 0 || self.second == 0) && self.minute == 0) {
            description += NSLocalizedString(String(format: "%dm", self.minute), comment: "")
        }
        if !((self.hour != 0 || self.minute != 0) && self.second == 0) {
            description += NSLocalizedString(String(format: "%ds", self.second), comment: "")
        }
        return description
    }
    
    static func timeUnit(of value: Double) -> STCTimeUnit {
        let timeUnit = STCTimeUnit()
        timeUnit.hour = Int(value) / 60
        timeUnit.minute = Int(value) % 60
        timeUnit.second = Int((value - Double(Int(value))) * 60)
        return timeUnit
    }
}
