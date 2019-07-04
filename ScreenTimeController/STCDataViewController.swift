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
    let countedItemViewController = STCCountedItemViewController(nibName: "STCCountedItemViewController", bundle: nil)
    
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
        self.tabView?.tabViewItem(at: 1).view = self.countedItemViewController.view
        self.tabView?.delegate = self
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.lastQueryID += 1
    }
    
    // MARK: transferrer for timed item
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
    
    func transferScreenTimeDeletionSuccessIndex(index: Int) {
        self.screenTimeViewController.deletionSuccess(of: index)
    }
    
    func transferScreenTimeDeletionError(error: STCDataModelError) {
        self.screenTimeViewController.deletionFailed(with: error)
    }
    
    func transferScreenTimeChangingSuccess(timedItem: STCTimedItem, index: Int) {
        self.screenTimeViewController.changeSuccess(of: index, with: timedItem)
    }
    
    func transferScreenTimeChangingError(error: STCDataModelError) {
        self.screenTimeViewController.changeFail(with: error)
    }
    
    // MARK: transferrer for counted item
    func transferCountedItem(countedItems: Array<STCCountedItem>) {
        DispatchQueue.main.async {
            if self.currentTabIndex == 1 {
                self.countedItemViewController.readCountedItems(countedItems: countedItems)
            }
        }
    }
    
    func transferCountedItemError(error: STCDataModelError) {
        DispatchQueue.main.async {
            if self.currentTabIndex == 1 {
                self.countedItemViewController.queryFailed(with: error)
            }
        }
    }
    
    func transferCountedItemDeletionSuccessIndex(index: Int) {
        self.countedItemViewController.deletionSuccess(of: index)
    }
    
    func transferCountedItemDeletionError(error: STCDataModelError) {
        self.countedItemViewController.deletionFailed(with: error)
    }
    
    func transferCountedItemChangingSuccess(countedItem: STCCountedItem, index: Int) {
        self.countedItemViewController.changeSuccess(of: index, with: countedItem)
    }
    
    func transferCountedItemChangingError(error: STCDataModelError) {
        self.countedItemViewController.changeFail(with: error)
    }
}
