//
//  STCDataViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/30.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa

class STCDataViewController: NSViewController {
    
    @IBOutlet var tabView: NSTabView?
    let screenTimeViewController = STCScreenTimeViewController(nibName: "STCScreenTimeViewController", bundle: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tabView?.tabViewItem(at: 0).view = self.screenTimeViewController.view
    }
    
}
