//
//  AppDelegate.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/25.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")

        window.contentView = NSHostingView(rootView: ContentView())

        window.makeKeyAndOrderFront(nil)
        
        let dataModel = STCDataModel()
        do {
            try dataModel.connectDatabase()
            try dataModel.blocks(since: Date(timeIntervalSinceNow: -3600 * 24), to: Date())
        } catch let error as STCDataModelError {
            switch error {
            case .executableNotExist:
                print("executable not exist!")
                
            case .fileNotExist:
                print("file not exist!")
                
            case .connectionFail:
                print("connection fail!")
                
            case .blockTableNotFound:
                print("block table not found!")
                
            case .categoryTableNotFound:
                print("category table not found!")
                
            case .timedItemTableNotFound:
                print("timed item table not found!")
                
            case .entryNotFound:
                print("entry not found!")
                
            case .unknown:
                print("unknown fail!")
            }
        } catch {}
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

