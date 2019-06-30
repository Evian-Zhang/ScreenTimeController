//
//  STCMainWindowController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCMainWindowController: NSWindowController {
    
    var dataMoodel: STCDataModel?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.dataMoodel = STCDataModel()
        
        NotificationCenter.default.addObserver(self, selector: #selector(databaseConnectionSuccessHandler), name: .STCDatabaseConnectionSuccess, object: nil)
    }
    
    func windowDidFirstDisplay() {
        let connectionViewController = STCConnectingViewController(nibName: "STCConnectingViewController", bundle: nil)
        self.window?.contentViewController = connectionViewController
        do {
            try self.dataMoodel?.connectDatabase()
        } catch let error as STCDataModelError {
            connectionViewController.databaseConnectionFail(with: error)
        } catch { }
    }
    
    @objc func databaseConnectionSuccessHandler() {
        let connectionViewController = self.window?.contentViewController as! STCConnectingViewController
        connectionViewController.databaseConnectionSuccess()
        self.window?.contentViewController = STCDataViewController(nibName: "STCDataViewController", bundle: nil)
    }
}
