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
        NotificationCenter.default.addObserver(self, selector: #selector(screenTimeChangeHandler(aNotification:)), name: .STCScreenTimeChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(countedItemQueryHandler(aNotification:)), name: .STCCountedItemQueryStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(countedItemDeleteHandler(aNotification:)), name: .STCCountedItemDelete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(countedItemChangeHandler(aNotification:)), name: .STCCountedItemChange, object: nil)
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
    
    // MARK: handle for timed item
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
            dataViewController.transferScreenTimeDeletionSuccessIndex(index: index)
        } catch let error as STCDataModelError {
            dataViewController.transferScreenTimeDeletionError(error: error)
        } catch { }
    }
    
    @objc func screenTimeChangeHandler(aNotification: Notification) {
        let userInfo = aNotification.userInfo
        let changingItem = userInfo!["changingItem"] as! STCTimedItem
        let index = userInfo!["index"] as! Int
        
        let dataViewController = self.window?.contentViewController as! STCDataViewController
        
        do {
            try self.dataModel?.changeTimeEntry(timedItem: changingItem)
            dataViewController.transferScreenTimeChangingSuccess(timedItem: changingItem, index: index)
        } catch let error as STCDataModelError {
            dataViewController.transferScreenTimeChangingError(error: error)
        } catch { }
    }
    
    // MARK: handle for counted item
    @objc func countedItemQueryHandler(aNotification: Notification) {
        let userInfo = aNotification.userInfo
        let searchType = userInfo!["searchType"] as! STCSearchType
        let content = userInfo!["content"] as! String?
        let startDate = userInfo!["startDate"] as! Date?
        let endDate = userInfo!["endDate"] as! Date?
        let queryID = userInfo!["queryID"] as! UInt32
        
        let dataViewController = self.window?.contentViewController as! STCDataViewController
        dataViewController.lastQueryID = queryID
        
        DispatchQueue.global().async {
            var countedItems: Array<STCCountedItem>
            do {
                try countedItems = (self.dataModel?.countedItems(since: startDate, to: endDate, of: content, by: searchType))!
                if dataViewController.lastQueryID == queryID {
                    dataViewController.transferCountedItem(countedItems: countedItems)
                }
            } catch let error as STCDataModelError {
                if dataViewController.lastQueryID == queryID {
                    dataViewController.transferCountedItemError(error: error)
                }
            } catch { }
        }
    }
    
    @objc func countedItemDeleteHandler(aNotification: Notification) {
        let userInfo = aNotification.userInfo
        let deletingItem = userInfo!["deletingItem"] as! STCCountedItem
        let index = userInfo!["index"] as! Int
        
        let dataViewController = self.window?.contentViewController as! STCDataViewController
        
        do {
            try self.dataModel?.deleteCountedItem(countedItem: deletingItem)
            dataViewController.transferCountedItemDeletionSuccessIndex(index: index)
        } catch let error as STCDataModelError {
            dataViewController.transferCountedItemDeletionError(error: error)
        } catch { }
    }
    
    @objc func countedItemChangeHandler(aNotification: Notification) {
        let userInfo = aNotification.userInfo
        let changingItem = userInfo!["changingItem"] as! STCCountedItem
        let index = userInfo!["index"] as! Int
        
        let dataViewController = self.window?.contentViewController as! STCDataViewController
        
        do {
            try self.dataModel?.changeCountedItem(countedItem: changingItem)
            dataViewController.transferCountedItemChangingSuccess(countedItem: changingItem, index: index)
        } catch let error as STCDataModelError {
            dataViewController.transferCountedItemChangingError(error: error)
        } catch { }
    }
}
