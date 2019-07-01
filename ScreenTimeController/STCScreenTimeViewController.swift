//
//  STCScreenTimeViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCScreenTimeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet var popUpButton: NSPopUpButton?
    @IBOutlet var contentField:  NSTextField?
    @IBOutlet var startDatePicker: NSDatePicker?
    @IBOutlet var endDatePicker: NSDatePicker?
    @IBOutlet var queryButton: NSButton?
    @IBOutlet var progressIndicator: NSProgressIndicator?
    @IBOutlet var informativeField: NSTextField?
    @IBOutlet var screenTimeTable: NSTableView?
    
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
                text += "Block table not found! "

            case .categoryTableNotFound:
                text += "Category table not found! "

            case .timedItemTableNotFound:
                text += "Timed item table not found! "

            case .installedAppTableNotFound:
                text += "Installed app table not found!"

            case .entryNotFound:
                text += "Entry not found!"
                
            default:
                text += "Unknown. "
            }
            self.informativeField?.stringValue = text
            self.informativeField?.textColor = .red
        }
    }
    
    override func viewWillDisappear() {
        self.progressIndicator?.stopAnimation(nil)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.timeEntries?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let timeEntry = self.timeEntries![row]
        var text = ""
        var identifier: NSUserInterfaceItemIdentifier
        
        let formatter = DateFormatter()
        formatter.locale = Locale.init(identifier: "zh_CN")
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
            return view
        }
        return nil
    }
}
