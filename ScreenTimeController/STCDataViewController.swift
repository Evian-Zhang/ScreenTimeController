//
//  STCDataViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCDataViewController: NSViewController, NSTabViewDelegate {
    
    @IBOutlet var tabView: NSTabView?
    
    let screenTimeViewController = STCScreenTimeViewController(nibName: "STCScreenTimeViewController", bundle: nil)
    
    var lastQueryID: UInt32 = 0
    
    var currentTabIndex: Int {
        get {
            return (self.tabView?.indexOfTabViewItem((self.tabView?.selectedTabViewItem)!))!
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tabView?.tabViewItem(at: 0).view = self.screenTimeViewController.view
        self.tabView?.delegate = self
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.lastQueryID += 1
    }
    
    func transferTimeEntry(timeEntry: Array<STCTimedItem>) {
        DispatchQueue.main.async {
            if self.currentTabIndex == 0 {
                self.screenTimeViewController.readTimeEntries(timeEntries: timeEntry)
            }
        }
    }
    
    func transferScreenTimeError(error: STCDataModelError) {
        DispatchQueue.main.async {
            if self.currentTabIndex == 0 {
                self.screenTimeViewController.queryFailed(with: error)
            }
        }
    }
    
}
