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
    
    func blocks(since startTime: Date?, to endTime: Date?) throws -> Dictionary<Int, Date> {
        var blockDict = Dictionary<Int, Date>()
        
        let usageBlock = Table("ZUSAGEBLOCK")
        let Z_PK = Expression<Int>("Z_PK")
        let ZSTARTDATE = Expression<Int>("ZSTARTDATE")
        let startTimeInInt = Int(startTime!.timeIntervalSinceReferenceDate)
        let endTimeInInt = Int(endTime!.timeIntervalSinceReferenceDate)
        let query = usageBlock.select(Z_PK, ZSTARTDATE).filter(ZSTARTDATE >= startTimeInInt && ZSTARTDATE <= endTimeInInt)
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
    
    func timeEntries(since startTime: Date?, to endTime: Date?, of content: String?, by type: STCSearchType) throws -> Dictionary<Int, (Int, Int, Int, Date)> {
        var timeEntryDict = Dictionary<Int, (Int, Int, Int, Date)>()
        
        let categoryDict = try self.categories(since: startTime, to: endTime)
        
        let usageTimedItem = Table("ZUSAGETIMEDITEM")
        let Z_PK = Expression<Int>("Z_PK")
        let ZCATEGORY = Expression<Int>("ZCATEGORY")
        let ZTOTALTIMEINSECONDS = Expression<Int>("ZTOTALTIMEINSECONDS")
        var ZCONTENT: Expression<String>
        switch type {
        case .applicationName:
            ZCONTENT = Expression<String>("")
        
        case .bundleID:
            ZCONTENT = Expression<String>("ZBUNDLEIDENTIFIER")
            
        case .domain:
            ZCONTENT = Expression<String>("ZDOMAIN")
        }
        
        let query = usageTimedItem.select(Z_PK, ZCATEGORY, ZTOTALTIMEINSECONDS).filter(categoryDict.keys.contains(ZCATEGORY) && ZCONTENT == content!)
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
                timeEntryDict.updateValue((ztotaltimeinseconds, zcategory, zblock, zstartdate), forKey: z_pk)
            }
        }
        
        return timeEntryDict
    }
}
