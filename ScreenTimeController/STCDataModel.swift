//
//  STCDataModel.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/27.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa
import SQLite

class STCDataModel: NSObject {

    var databasePath: String?
    var database: Connection?
    var deviceID: Int?
    var usage: Int?
    let busyTimeOut = 5.0
    let maxTriesCount = 3
    
    func determineDataBaseURL() throws {
        let process = Process()
        let outputPipe = Pipe()
        let readingHandle = outputPipe.fileHandleForReading
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/getconf")
        process.arguments = ["DARWIN_USER_DIR"]
        process.standardOutput = outputPipe
        
        do { try process.run() } catch { throw STCDataModelError.executableNotExist }
        
        process.waitUntilExit()
        
        if var darwinUserDirPath = String(data: readingHandle.readDataToEndOfFile(), encoding: .utf8) {
            if darwinUserDirPath.last == "\n" {
                darwinUserDirPath.removeLast()
            }
            self.databasePath = darwinUserDirPath + "com.apple.ScreenTimeAgent/Store/" + "RMAdminStore-Local.sqlite"
            if !FileManager.default.fileExists(atPath: self.databasePath!) {
                readingHandle.closeFile()
                throw STCDataModelError.fileNotExist
            }
        } else {
            readingHandle.closeFile()
            throw STCDataModelError.unknown
        }
        readingHandle.closeFile()
    }
    
    func connectDatabase() throws {
        try self.determineDataBaseURL()
        do {
            try self.database = Connection(self.databasePath!)
        } catch {
            throw STCDataModelError.connectionFail
        }
        self.database?.busyTimeout = self.busyTimeOut
        self.database?.busyHandler({ tries in
            if tries >= self.maxTriesCount {
                return false
            }
            return true
        })
        NotificationCenter.default.post(name: .STCDatabaseConnectionSuccess, object: nil, userInfo:nil);
    }
    
    func determineDeviceID() throws {
        let userDeviceState = Table("ZUSERDEVICESTATE")
        let ZDEVICE = Expression<Int>("ZDEVICE")
        let ZLOCALDEVICE = Expression<Int?>("ZLOCALDEVICE")
        let query = userDeviceState.select(ZDEVICE).filter(ZLOCALDEVICE == 1)
        var results: AnySequence<Row>
        do {
            try results = self.database!.prepare(query)
        } catch {
            throw STCDataModelError.deviceStateTableNotFound
        }
        let resultsArray = Array(results)
        if resultsArray.count == 0 {
            throw STCDataModelError.unknown
        } else if resultsArray.count > 1 {
            throw STCDataModelError.multipleUsers
        }
        
        do {
            try self.deviceID = resultsArray[0].get(ZDEVICE)
        } catch {
            throw STCDataModelError.entryNotFound
        }
    }
    
    func determineUsage() throws {
        try self.determineDeviceID()
        
        let usage = Table("ZUSAGE")
        let Z_PK = Expression<Int?>("Z_PK")
        let ZDEVICE = Expression<Int>("ZDEVICE")
        let query = usage.select(Z_PK).filter(ZDEVICE == self.deviceID ?? 0)
        var results: AnySequence<Row>
        do {
            try results = self.database!.prepare(query)
        } catch {
            throw STCDataModelError.usageTableNotFound
        }
        let resultsArray = Array(results)
        if resultsArray.count == 0 {
            throw STCDataModelError.unknown
        } else if resultsArray.count > 1 {
            throw STCDataModelError.multipleUsers
        }
        
        do {
            try self.usage = resultsArray[0].get(Z_PK)
        } catch {
            throw STCDataModelError.entryNotFound
        }
    }
    
    func blocks(since startTime: Date?, to endTime: Date?) throws -> Dictionary<Int, Date> {
        var blockDict = Dictionary<Int, Date>()
        
        let usageBlock = Table("ZUSAGEBLOCK")
        let Z_PK = Expression<Int>("Z_PK")
        let ZSTARTDATE = Expression<Int>("ZSTARTDATE")
        let ZUSAGE = Expression<Int>("ZUSAGE")
        let startTimeInInt = Int(startTime!.timeIntervalSinceReferenceDate)
        let endTimeInInt = Int(endTime!.timeIntervalSinceReferenceDate)
        let query = usageBlock.select(Z_PK, ZSTARTDATE).filter(ZSTARTDATE >= startTimeInInt && ZSTARTDATE <= endTimeInInt && ZUSAGE == self.usage ?? 0)
        var results: AnySequence<Row>
        do {
            try results = self.database!.prepare(query)
        } catch {
            throw STCDataModelError.blockTableNotFound
        }
        do {
            for entry in results {
                let z_pk = try entry.get(Z_PK)
                let zstartdate = try Date(timeIntervalSinceReferenceDate: TimeInterval(entry.get(ZSTARTDATE)))
                blockDict.updateValue(zstartdate, forKey: z_pk)
            }
        } catch {
            throw STCDataModelError.entryNotFound
        }
        
        return blockDict
    }
    
    func categories(since startTime: Date?, to endTime: Date?) throws -> Dictionary<Int, (Int, Date)> {
        var categoryDict = Dictionary<Int, (Int, Date)>()
        
        let blockDict = try self.blocks(since: startTime, to: endTime)
        
        let usageCategory = Table("ZUSAGECATEGORY")
        let Z_PK = Expression<Int>("Z_PK")
        let ZBLOCK = Expression<Int>("ZBLOCK")
        
        let query = usageCategory.select(Z_PK, ZBLOCK).filter(blockDict.keys.contains(ZBLOCK))
        var results: AnySequence<Row>
        do {
            try results = self.database!.prepare(query)
        } catch {
            throw STCDataModelError.categoryTableNotFound
        }
        do {
            for entry in results {
                let z_pk = try entry.get(Z_PK)
                let zblock = try entry.get(ZBLOCK)
                categoryDict.updateValue((zblock, blockDict[zblock]!), forKey: z_pk)
            }
        } catch {
            throw STCDataModelError.entryNotFound
        }
        
        return categoryDict
    }
    
    func bundleID(of applicationName: String?) throws -> String? {
        let installedApp = Table("ZINSTALLEDAPP")
        let ZBUNDLEIDENTIFIER = Expression<String>("ZBUNDLEIDENTIFIER")
        let ZDISPLAYNAME = Expression<String>("ZDISPLAYNAME")
        let query = installedApp.select(ZBUNDLEIDENTIFIER).filter(ZDISPLAYNAME == applicationName!)
        var results: AnySequence<Row>
        
        do {
            try results = self.database!.prepare(query)
        } catch {
            throw STCDataModelError.installedAppTableNotFound
        }
        let resultsArray = Array(results)
        if (resultsArray.count > 1) {
            throw STCDataModelError.unknown
        } else if (resultsArray.count == 0) {
            throw STCDataModelError.entryNotFound
        }
        var zbundleidentifier: String?
        do {
            zbundleidentifier = try resultsArray[0].get(ZBUNDLEIDENTIFIER)
        } catch {
            throw STCDataModelError.entryNotFound
        }
        return zbundleidentifier
    }
    
    func timeEntries(since startTime: Date?, to endTime: Date?, of content: String?, by type: STCSearchType) throws -> Array<STCTimedItem> {
        var timeEntries = Array<STCTimedItem>()
        
        let usageTimedItem = Table("ZUSAGETIMEDITEM")
        let Z_PK = Expression<Int>("Z_PK")
        let ZCATEGORY = Expression<Int>("ZCATEGORY")
        let ZTOTALTIMEINSECONDS = Expression<Int>("ZTOTALTIMEINSECONDS")
        var ZCONTENT: Expression<String>
        var queryContent = content
        switch type {
        case .applicationName:
            ZCONTENT = Expression<String>("ZBUNDLEIDENTIFIER")
            try queryContent = self.bundleID(of: content)
        
        case .bundleID:
            ZCONTENT = Expression<String>("ZBUNDLEIDENTIFIER")
            
        case .domain:
            ZCONTENT = Expression<String>("ZDOMAIN")
        }
        
        let categoryDict = try self.categories(since: startTime, to: endTime)
        
        let query = usageTimedItem.select(Z_PK, ZCATEGORY, ZTOTALTIMEINSECONDS).filter(categoryDict.keys.contains(ZCATEGORY) && ZCONTENT == queryContent!)
        var results: AnySequence<Row>
        do {
            try results = self.database!.prepare(query)
        } catch {
            throw STCDataModelError.timedItemTableNotFound
        }
        do {
            for entry in results {
                let z_pk = try entry.get(Z_PK)
                let zcategory = try entry.get(ZCATEGORY)
                let ztotaltimeinseconds = try entry.get(ZTOTALTIMEINSECONDS)
                let (zblock, zstartdate) = categoryDict[zcategory]!
                timeEntries.append(STCTimedItem(z_pk: z_pk, ztotaltimeinseconds: ztotaltimeinseconds, zblock: zblock, zcategory: zcategory, zstartdate: zstartdate))
            }
        }
        
        timeEntries.sort { (a, b) -> Bool in
            return a.compare(other: b) == .orderedAscending
        }
        return timeEntries
    }
}
