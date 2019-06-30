//
//  STCScreenTimeViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCScreenTimeViewController: NSViewController {
    
    @IBOutlet var popUpButton: NSPopUpButton?
    @IBOutlet var contentField:  NSTextField?
    @IBOutlet var startDatePicker: NSDatePicker?
    @IBOutlet var endDatePicker: NSDatePicker?
    @IBOutlet var queryButton: NSButton?
    @IBOutlet var screenTimeTable: NSTableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.queryButton?.target = self
        self.queryButton?.action = #selector(queryButtonHandler)
        self.popUpButton?.addItems(withTitles: [NSLocalizedString("Application Name", comment: ""), NSLocalizedString("Bundle ID", comment: ""), NSLocalizedString("Domain", comment: "")])
    }
    
    func canQuery() -> (Bool, String?) {
        var canQuery = true
        var reason = ""
        if self.contentField?.stringValue.count ?? 0 > 0 {
            canQuery = false
            reason += NSLocalizedString("Query content can't be empty.\n", comment: "")
        }
        if self.startDatePicker?.dateValue.compare(self.endDatePicker!.dateValue) != .orderedAscending {
            canQuery = false
            reason += NSLocalizedString("Query date error.\n", comment: "")
        }
        if !canQuery {
            return (canQuery, reason)
        }
        return (canQuery, nil)
    }
    
    @objc func queryButtonHandler() {
        let (canQuery, reason) = self.canQuery()
        if (!canQuery) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Error, please retry.", comment: "")
            alert.informativeText = reason!
            alert.runModal()
        } else {
            
        }
    }
}
