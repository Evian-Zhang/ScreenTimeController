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
    
    func blocks(since startTime: Date?, to endTime: Date?) throws -> Array<Int> {
        var blocks = Array<Int>()
        Table
        return blocks
    }
}
