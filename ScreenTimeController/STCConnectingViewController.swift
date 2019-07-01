//
//  STCConnectingViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCConnectingViewController: NSViewController {
    
    @IBOutlet var progressIndicator: NSProgressIndicator?
    @IBOutlet var connectingLabel: NSTextField?
    @IBOutlet var okButton: NSButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.progressIndicator?.isDisplayedWhenStopped = false
        self.progressIndicator?.startAnimation(nil)
        self.okButton?.isHidden = true
        self.okButton?.target = self
        self.okButton?.action = #selector(okButtonHandler)
    }
    
    func databaseConnectionSuccess() {
        self.progressIndicator?.stopAnimation(nil)
    }
    
    func databaseConnectionFail(with error: STCDataModelError) {
        self.progressIndicator?.stopAnimation(nil)
        self.okButton?.isHidden = false
        switch error {
        case .executableNotExist:
            self.connectingLabel?.stringValue = NSLocalizedString("Executable `getconf` not exists!", comment: "")
            
        case .fileNotExist:
            self.connectingLabel?.stringValue = NSLocalizedString("Database file not exists!", comment: "")
            
        case .connectionFail:
            self.connectingLabel?.stringValue = NSLocalizedString("Database connection failed!", comment: "")
            
        case .deviceStateTableNotFound:
            self.connectingLabel?.stringValue = NSLocalizedString("Cannot determine local device", comment: "")
            
        case .usageTableNotFound:
            self.connectingLabel?.stringValue = NSLocalizedString("Cannot determine local device", comment: "")
            
        case .multipleUsers:
            self.connectingLabel?.stringValue = NSLocalizedString("Multiple users are temporally not supported", comment: "")
            
        default:
            self.connectingLabel?.stringValue = NSLocalizedString("Unknown", comment: "")
        }
    }
    
    @objc func okButtonHandler() {
        NSApp.terminate(nil)
    }
}
