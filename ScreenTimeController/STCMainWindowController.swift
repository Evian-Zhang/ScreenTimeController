//
//  STCMainWindowController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCMainWindowController: NSWindowController {
    
    var dataModel: STCDataModel?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.dataModel = STCDataModel()
        
        NotificationCenter.default.addObserver(self, selector: #selector(databaseConnectionSuccessHandler), name: .STCDatabaseConnectionSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenTimeQueryHandler(aNotification:)), name: .STCScreenTimeQueryStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenTimeDeleteHandler(aNotification:)), name: .STCScreenTimeDelete, object: nil)
    }
    
    func windowDidFirstDisplay() {
        let connectionViewController = STCConnectingViewController(nibName: "STCConnectingViewController", bundle: nil)
        self.window?.contentViewController = connectionViewController
        do {
            try self.dataModel?.connectDatabase()
            try self.dataModel?.determineUsage()
        } catch let error as STCDataModelError {
            connectionViewController.databaseConnectionFail(with: error)
        } catch { }
    }
    
    @objc func databaseConnectionSuccessHandler() {
        let connectionViewController = self.window?.contentViewController as! STCConnectingViewController
        connectionViewController.databaseConnectionSuccess()
        self.window?.contentViewController = STCDataViewController(nibName: "STCDataViewController", bundle: nil)
    }
    
    @objc func screenTimeQueryHandler(aNotification: Notification) {
        let userInfo = aNotification.userInfo
        let searchType = userInfo!["searchType"] as! STCSearchType
        let content = userInfo!["content"] as! String?
        let startDate = userInfo!["startDate"] as! Date?
        let endDate = userInfo!["endDate"] as! Date?
        let queryID = userInfo!["queryID"] as! UInt32
        
        let dataViewController = self.window?.contentViewController as! STCDataViewController
        dataViewController.lastQueryID = queryID
        
        DispatchQueue.global().async {
            var timeEntries: Array<STCTimedItem>
            do {
                try timeEntries = (self.dataModel?.timeEntries(since: startDate, to: endDate, of: content, by: searchType))!
                if dataViewController.lastQueryID == queryID {
                    dataViewController.transferTimeEntry(timeEntry: timeEntries)
                }
            } catch let error as STCDataModelError {
                if dataViewController.lastQueryID == queryID {
                    dataViewController.transferScreenTimeError(error: error)
                }
            } catch { }
        }
    }
    
    @objc func screenTimeDeleteHandler(aNotification: Notification) {
        let userInfo = aNotification.userInfo
        let deletingItem = userInfo!["deletingItem"] as! STCTimedItem
        let index = userInfo!["index"] as! Int
        
        let dataViewController = self.window?.contentViewController as! STCDataViewController
        
        do {
            try self.dataModel?.deleteTimeEntry(timedItem: deletingItem)
            dataViewController.transferDeletionSuccessIndex(index: index)
        } catch let error as STCDataModelError {
            dataViewController.transferScreenTimeDeletionError(error: error)
        } catch { }
    }
}
