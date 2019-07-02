//
//  STCScreenTimeViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCScreenTimeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSMenuItemValidation, NSTextFieldDelegate {
    
    @IBOutlet var popUpButton: NSPopUpButton?
    @IBOutlet var contentField:  NSTextField?
    @IBOutlet var startDatePicker: NSDatePicker?
    @IBOutlet var endDatePicker: NSDatePicker?
    @IBOutlet var queryButton: NSButton?
    @IBOutlet var progressIndicator: NSProgressIndicator?
    @IBOutlet var informativeField: NSTextField?
    @IBOutlet var screenTimeTable: NSTableView?
    @IBOutlet var tableMenu: NSMenu?
    @IBOutlet var deleteMenuItem: NSMenuItem?
    
    var timeEntries: Array<STCTimedItem>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.queryButton?.target = self
        self.queryButton?.action = #selector(queryButtonHandler)
        self.popUpButton?.addItems(withTitles: [NSLocalizedString("Application Name", comment: ""), NSLocalizedString("Bundle ID", comment: ""), NSLocalizedString("Domain", comment: "")])
        self.progressIndicator?.isHidden = true
        self.progressIndicator?.isDisplayedWhenStopped = false
        self.screenTimeTable?.delegate = self
        self.screenTimeTable?.dataSource = self
        self.screenTimeTable?.menu = self.tableMenu
        self.deleteMenuItem?.target = self
        self.deleteMenuItem?.action = #selector(deleteItemHandler)
    }
    
    func canQuery() -> (Bool, String?) {
        var canQuery = true
        var reason = ""
        if self.contentField?.stringValue.count ?? 0 == 0 {
            canQuery = false
            reason += NSLocalizedString("Query content can't be empty. ", comment: "")
        }
        if self.startDatePicker?.dateValue.compare(self.endDatePicker!.dateValue) != .orderedAscending {
            canQuery = false
            reason += NSLocalizedString("Query date error. ", comment: "")
        }
        if !canQuery {
            return (canQuery, reason)
        }
        return (canQuery, nil)
    }
    
    @objc func queryButtonHandler() {
        self.informativeField?.stringValue = ""
        let (canQuery, reason) = self.canQuery()
        if (!canQuery) {
            self.informativeField?.textColor = .red
            self.informativeField?.stringValue = reason!
        } else {
            self.progressIndicator?.isHidden = false
            self.progressIndicator?.startAnimation(nil)
            
            var searchType: STCSearchType = .applicationName
            switch self.popUpButton?.indexOfSelectedItem {
            case 0:
                searchType = .applicationName
                
            case 1:
                searchType = .bundleID
                
            case 2:
                searchType = .domain
                
            default:
                break
            }
            
            let content = self.contentField?.stringValue
            let startDate = self.startDatePicker?.dateValue
            let endDate = self.endDatePicker?.dateValue
            let queryID = arc4random() % 1024
            
            let userInfo = ["searchType": searchType, "content": content!, "startDate": startDate!, "endDate": endDate!, "queryID": queryID] as [String : Any]
            NotificationCenter.default.post(name: .STCScreenTimeQueryStart, object: nil, userInfo: userInfo)
        }
    }
    
    func readTimeEntries(timeEntries: Array<STCTimedItem>) {
        self.progressIndicator?.stopAnimation(nil)
        self.timeEntries = timeEntries
        self.screenTimeTable?.reloadData()
    }
    
    func queryFailed(with error: STCDataModelError) {
        DispatchQueue.main.async {
            self.progressIndicator?.stopAnimation(nil)
            var text = ""
            switch error {
            case .blockTableNotFound:
                text += NSLocalizedString("Block table not found! ", comment: "")

            case .categoryTableNotFound:
                text += NSLocalizedString("Category table not found! ", comment: "")

            case .timedItemTableNotFound:
                text += NSLocalizedString("Timed item table not found! ", comment: "")

            case .installedAppTableNotFound:
                text += NSLocalizedString("Installed app table not found!", comment: "")

            case .entryNotFound:
                text += NSLocalizedString("Entry not found!", comment: "")
                
            default:
                text += NSLocalizedString("Unknown error. ", comment: "")
            }
            self.informativeField?.stringValue = text
            self.informativeField?.textColor = .red
        }
    }
    
    override func viewWillDisappear() {
        if self.progressIndicator?.isHidden == false {
            self.progressIndicator?.stopAnimation(nil)
        }
    }
    
    // MARK: handle delete
    @objc func deleteItemHandler() {
        let index = self.screenTimeTable?.clickedRow
        if index ?? -1 < 0 {
            return
        }
        
        let deletingItem = self.timeEntries?[index!]
        NotificationCenter.default.post(name: .STCScreenTimeDelete, object: nil, userInfo: ["deletingItem": deletingItem!, "index": index!])
    }
    
    func deletionSuccess(of index: Int) {
        self.timeEntries?.remove(at: index)
        if self.isViewLoaded && self.view.window != nil {
            self.screenTimeTable?.reloadData()
        }
    }
    
    func deletionFailed(with error: STCDataModelError) {
        var reason = ""
        switch error {
        case .deleteFail:
            reason = NSLocalizedString("Deletion failed!", comment: "")
            
        case .entryNotFound:
            reason = NSLocalizedString("Entry not found!", comment: "")
            
        default:
            reason = NSLocalizedString("Unknown error.", comment: "")
        }
        if self.isViewLoaded && self.view.window != nil {
            self.informativeField?.stringValue = reason
            self.informativeField?.textColor = .red
        }
    }
    
    // MARK: handle change
    func changeSuccess(of index: Int, with newTimedItem: STCTimedItem) {
        self.timeEntries![index] = newTimedItem
        if self.isViewLoaded && self.view.window != nil {
            self.screenTimeTable?.reloadData()
        }
    }
    
    func changeFail(with error: STCDataModelError){
        var reason = ""
        switch error {
        case .changeFail:
            reason = NSLocalizedString("Change error.", comment: "")
            
        default:
            reason = NSLocalizedString("Unknown error.", comment: "")
        }
        if self.isViewLoaded && self.view.window != nil {
            self.informativeField?.stringValue = reason
            self.informativeField?.textColor = .red
        }
    }
    
    // MARK: conform to NSTableViewDelegate and NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.timeEntries?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let timeEntry = self.timeEntries![row]
        var text = ""
        var identifier: NSUserInterfaceItemIdentifier
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        switch tableColumn?.identifier.rawValue {
        case "STCScreenTimeTableStartTimeColumn":
            text = formatter.string(from: timeEntry.zstartdate)
            identifier = NSUserInterfaceItemIdentifier("STCScreenTimeTableStartTime")
            
        case "STCScreenTimeTableDurationColumn":
            text = String(timeEntry.ztotaltimeinseconds)
            identifier = NSUserInterfaceItemIdentifier("STCScreenTimeTableDuration")
            
        default:
            text = ""
            identifier = NSUserInterfaceItemIdentifier("")
        }
        
        if let view = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = text
            if tableColumn?.identifier.rawValue == "STCScreenTimeTableDurationColumn" {
                view.textField?.isEditable = true
                view.textField?.delegate = self
                let numberFormatter = NumberFormatter()
                numberFormatter.minimum = 0
                numberFormatter.allowsFloats = false
                view.textField?.formatter = numberFormatter
            }
            return view
        }
        return nil
    }
    
    // MARK: conform to NSMenuItemValidation
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let index = self.screenTimeTable?.clickedRow
        if menuItem.action == #selector(deleteItemHandler) && index ?? -1 >= 0 {
            return true
        }
        return false
    }
    
    // MARK: conform to NSTextFieldDelegate
    func controlTextDidEndEditing(_ obj: Notification) {
        let textField = obj.object as? NSTextField
        let currentDuration = Int(textField?.intValue ?? 0)
        let index = self.screenTimeTable?.row(for: textField!)
        if index ?? -1 >= 0 {
            var changingItem = self.timeEntries![index!]
            let previousDuration = changingItem.ztotaltimeinseconds
            if currentDuration != previousDuration {
                changingItem.ztotaltimeinseconds = currentDuration
                NotificationCenter.default.post(name: .STCScreenTimeChange, object: nil, userInfo: ["changingItem": changingItem, "index": index!])
            }
        }
    }
    
    func control(_ control: NSControl, didFailToFormatString string: String, errorDescription error: String?) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Error, please change your input.", comment: "")
        alert.informativeText = NSLocalizedString("Only supports integer not less than 0.", comment: "")
        let index = self.screenTimeTable?.row(for: control)
        alert.runModal()
        if index ?? -1 >= 0 {
            let previousDuration = self.timeEntries![index!].ztotaltimeinseconds
            let textField = control as? NSTextField
            textField?.stringValue = String(previousDuration)
        }
        
        return false
    }
}
