//
//  STCCountedItemViewController.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/7/4.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Cocoa
import Charts

class STCCountedItemViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSMenuItemValidation, NSTextFieldDelegate, IAxisValueFormatter, IValueFormatter {
    @IBOutlet var popUpButton: NSPopUpButton?
    @IBOutlet var contentField:  NSTextField?
    @IBOutlet var startDatePicker: NSDatePicker?
    @IBOutlet var endDatePicker: NSDatePicker?
    @IBOutlet var queryButton: NSButton?
    @IBOutlet var progressIndicator: NSProgressIndicator?
    @IBOutlet var informativeField: NSTextField?
    @IBOutlet var countedItemTable: NSTableView?
    @IBOutlet var tableMenu: NSMenu?
    @IBOutlet var deleteMenuItem: NSMenuItem?
    @IBOutlet var combinedChartView: CombinedChartView?
    @IBOutlet var chartDisplayPopUpButton: NSPopUpButton?

    var countedItems: Array<STCCountedItem>?
    var chartXEntries: Array<Date>?
    var notificationEntries: Array<Int>?
    var pickupEntries: Array<Int>?
    var currentDisplayUnit = STCDisplayUnit.day
    
    let barWidth = 0.4
    let barSpace = 0.05
    let barChartDataSetColor = NSColor.red
    let lineChartDataSetColor = NSColor.yellow
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.queryButton?.target = self
        self.queryButton?.action = #selector(queryButtonHandler)
        self.popUpButton?.removeAllItems()
        self.popUpButton?.addItems(withTitles: [NSLocalizedString("Application Name", comment: ""), NSLocalizedString("Bundle ID", comment: "")])
        self.chartDisplayPopUpButton?.removeAllItems()
        self.chartDisplayPopUpButton?.addItems(withTitles: [NSLocalizedString("Hour", comment: ""), NSLocalizedString("Day", comment: ""), NSLocalizedString("Week", comment: ""), NSLocalizedString("Month", comment: ""), NSLocalizedString("Year", comment: "")])
        self.chartDisplayPopUpButton?.target = self
        self.chartDisplayPopUpButton?.action = #selector(chartDisplayPopUpButtonHandler)
        self.chartDisplayPopUpButton?.autoenablesItems = false
        self.chartDisplayPopUpButton?.selectItem(at: 1)
        self.currentDisplayUnit = .day
        self.progressIndicator?.isHidden = true
        self.progressIndicator?.isDisplayedWhenStopped = false
        self.countedItemTable?.delegate = self
        self.countedItemTable?.dataSource = self
        self.countedItemTable?.menu = self.tableMenu
        self.deleteMenuItem?.target = self
        self.deleteMenuItem?.action = #selector(deleteItemHandler)
        
        self.combinedChartView?.doubleTapToZoomEnabled = false
        self.combinedChartView?.highlightPerTapEnabled = false
        self.combinedChartView?.gridBackgroundColor = .white
        self.combinedChartView?.legend.enabled = false
        self.combinedChartView?.xAxis.labelPosition = .bottom
        self.combinedChartView?.xAxis.valueFormatter = self
        self.combinedChartView?.xAxis.labelTextColor = .textColor
        self.combinedChartView?.leftAxis.valueFormatter = self
        self.combinedChartView?.leftAxis.labelTextColor = .textColor
        self.combinedChartView?.rightAxis.valueFormatter = self
        self.combinedChartView?.rightAxis.labelTextColor = .textColor
        self.combinedChartView?.noDataTextColor = .textColor
        self.combinedChartView?.noDataText = NSLocalizedString("No data Available", comment: "")
    }
    
    func processChartData(countedItems: Array<STCCountedItem>) {
        switch self.chartDisplayPopUpButton?.indexOfSelectedItem {
        case 0:
            self.prepareForHour(of: countedItems)
            
        case 1:
            self.prepareForDay(of: countedItems)
            
        case 2:
            self.prepareForWeek(of: countedItems)
            
        case 3:
            self.prepareForMonth(of: countedItems)
            
        case 4:
            self.prepareForYear(of: countedItems)
            
        default:
            self.prepareForDay(of: countedItems)
        }
    }
    
    func processChart() {
        var notificationDataEntries = Array<BarChartDataEntry>()
        var pickupDataEntries = Array<ChartDataEntry>()
        for index in 0 ..< (self.notificationEntries?.count)! {
            notificationDataEntries.append(BarChartDataEntry(x: Double(index), y: Double(self.notificationEntries![index])))
            pickupDataEntries.append(ChartDataEntry(x: Double(index), y:  Double(self.pickupEntries![index])))
        }
        let barChartData = BarChartData()
        let notificationDataSet = BarChartDataSet(entries: notificationDataEntries)
        notificationDataSet.colors = [self.barChartDataSetColor]
        barChartData.addDataSet(notificationDataSet)
        barChartData.barWidth = self.barWidth
        barChartData.setValueFormatter(self)
        barChartData.setValueTextColor(.textColor)
        
        let lineChartData = LineChartData()
        let pickupDataSet = LineChartDataSet(entries: pickupDataEntries)
        pickupDataSet.colors = [self.lineChartDataSetColor]
        pickupDataSet.fillColor = self.lineChartDataSetColor
        lineChartData.addDataSet(pickupDataSet)
        lineChartData.setValueFormatter(self)
        lineChartData.setValueTextColor(.textColor)
        
        let combinedChartData = CombinedChartData()
        combinedChartData.barData = barChartData
        combinedChartData.lineData = lineChartData
        
        self.combinedChartView?.data = combinedChartData
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
    
    @objc func chartDisplayPopUpButtonHandler() {
        switch self.chartDisplayPopUpButton?.indexOfSelectedItem {
        case 0:
            self.currentDisplayUnit = .hour
            
        case 1:
            self.currentDisplayUnit = .day
            
        case 2:
            self.currentDisplayUnit = .week
            
        case 3:
            self.currentDisplayUnit = .month
            
        case 4:
            self.currentDisplayUnit = .year
            
        default:
            self.currentDisplayUnit = .day
        }
        if let countedItem = self.countedItems {
            if countedItem.count > 0 {
                self.processChartData(countedItems: countedItem)
                self.processChart()
                self.combinedChartView?.needsDisplay = true
            }
        }
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
                
            default:
                searchType = .bundleID
            }
            
            let content = self.contentField?.stringValue
            let startDate = self.startDatePicker?.dateValue
            let endDate = self.endDatePicker?.dateValue
            let queryID = arc4random() % 1024
            
            let userInfo = ["searchType": searchType, "content": content!, "startDate": startDate!, "endDate": endDate!, "queryID": queryID] as [String : Any]
            NotificationCenter.default.post(name: .STCCountedItemQueryStart, object: nil, userInfo: userInfo)
        }
    }
    
    func readCountedItems(countedItems: Array<STCCountedItem>) {
        self.countedItems = countedItems
        self.countedItemTable?.reloadData()
        
        self.processChartData(countedItems: countedItems)
        self.processChart()
        self.progressIndicator?.stopAnimation(nil)
    }
    
    func queryFailed(with error: STCDataModelError) {
        DispatchQueue.main.async {
            self.progressIndicator?.stopAnimation(nil)
            var text = ""
            switch error {
            case .blockTableNotFound:
                text += NSLocalizedString("Block table not found! ", comment: "")
                
            case .countedItemTableNotFound:
                text += NSLocalizedString("Counted item table not found! ", comment: "")
                
            case .installedAppTableNotFound:
                text += NSLocalizedString("Installed app table not found! ", comment: "")
                
            case .entryNotFound:
                text += NSLocalizedString("Entry not found! ", comment: "")
                
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
    
    // MARK: process chart data
    func prepareForHour(of countedItems: Array<STCCountedItem>) {
        if (countedItems.count == 0) {
            return
        }
        
        let firstHourRaw = (countedItems.first?.zstartdate)!
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: firstHourRaw)
        let firstHour = calendar.date(from: components)
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstHour!)
        self.notificationEntries = Array<Int>()
        self.notificationEntries?.append(0)
        self.pickupEntries = Array<Int>()
        self.pickupEntries?.append(0)
        var index = 0
        while index < countedItems.count {
            let thisEntry = countedItems[index]
            let nextUnit = calendar.date(byAdding: .hour, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                let lastNotificationValue = self.notificationEntries?.popLast()
                self.notificationEntries?.append((lastNotificationValue ?? 0) + thisEntry.znumberofnotifications)
                
                let lastPickupValue = self.pickupEntries?.popLast()
                self.pickupEntries?.append((lastPickupValue ?? 0) + thisEntry.znumberofpickups)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.notificationEntries?.append(0)
                self.pickupEntries?.append(0)
            }
        }
    }
    
    func prepareForDay(of countedItems: Array<STCCountedItem>) {
        if (countedItems.count == 0) {
            return
        }
        
        let firstDateRaw = countedItems.first?.zstartdate
        let calendar = Calendar.current
        let firstDate = calendar.startOfDay(for: firstDateRaw ?? Date())
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstDate)
        self.notificationEntries = Array<Int>()
        self.notificationEntries?.append(0)
        self.pickupEntries = Array<Int>()
        self.pickupEntries?.append(0)
        var index = 0
        while index < countedItems.count {
            let thisEntry = countedItems[index]
            let nextUnit = calendar.date(byAdding: .day, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                let lastNotificationValue = self.notificationEntries?.popLast()
                self.notificationEntries?.append((lastNotificationValue ?? 0) + thisEntry.znumberofnotifications)
                
                let lastPickupValue = self.pickupEntries?.popLast()
                self.pickupEntries?.append((lastPickupValue ?? 0) + thisEntry.znumberofpickups)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.notificationEntries?.append(0)
                self.pickupEntries?.append(0)
            }
        }
    }
    
    func prepareForWeek(of countedItems: Array<STCCountedItem>) {
        if (countedItems.count == 0) {
            return
        }
        
        let firstWeekRaw = countedItems.first?.zstartdate
        let calendar = Calendar.current
        let thisDay = calendar.startOfDay(for: firstWeekRaw!)
        let firstWeek = calendar.date(bySetting: .weekday, value: 1, of: thisDay)
        
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstWeek!)
        self.notificationEntries = Array<Int>()
        self.notificationEntries?.append(0)
        self.pickupEntries = Array<Int>()
        self.pickupEntries?.append(0)
        var index = 0
        while index < countedItems.count {
            let thisEntry = countedItems[index]
            let nextUnit = calendar.date(byAdding: .weekOfYear, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                let lastNotificationValue = self.notificationEntries?.popLast()
                self.notificationEntries?.append((lastNotificationValue ?? 0) + thisEntry.znumberofnotifications)
                
                let lastPickupValue = self.pickupEntries?.popLast()
                self.pickupEntries?.append((lastPickupValue ?? 0) + thisEntry.znumberofpickups)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.notificationEntries?.append(0)
                self.pickupEntries?.append(0)
            }
        }
    }
    
    func prepareForMonth(of countedItems: Array<STCCountedItem>) {
        if (countedItems.count == 0) {
            return
        }
        
        let firstMonthRaw = countedItems.first?.zstartdate
        let calendar = Calendar.current
        let thisDay = calendar.startOfDay(for: firstMonthRaw!)
        let firstMonth = calendar.date(bySetting: .day, value: 1, of: thisDay)
        
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstMonth!)
        self.notificationEntries = Array<Int>()
        self.notificationEntries?.append(0)
        self.pickupEntries = Array<Int>()
        self.pickupEntries?.append(0)
        var index = 0
        while index < countedItems.count {
            let thisEntry = countedItems[index]
            let nextUnit = calendar.date(byAdding: .month, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                let lastNotificationValue = self.notificationEntries?.popLast()
                self.notificationEntries?.append((lastNotificationValue ?? 0) + thisEntry.znumberofnotifications)
                
                let lastPickupValue = self.pickupEntries?.popLast()
                self.pickupEntries?.append((lastPickupValue ?? 0) + thisEntry.znumberofpickups)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.notificationEntries?.append(0)
                self.pickupEntries?.append(0)
            }
        }
    }
    
    func prepareForYear(of countedItems: Array<STCCountedItem>) {
        if (countedItems.count == 0) {
            return
        }
        
        let firstYearRaw = countedItems.first?.zstartdate
        let calendar = Calendar.current
        let thisDay = calendar.startOfDay(for: firstYearRaw!)
        let firstYear = calendar.date(from: calendar.dateComponents([.year], from: thisDay))
        
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstYear!)
        self.notificationEntries = Array<Int>()
        self.notificationEntries?.append(0)
        self.pickupEntries = Array<Int>()
        self.pickupEntries?.append(0)
        var index = 0
        while index < countedItems.count {
            let thisEntry = countedItems[index]
            let nextUnit = calendar.date(byAdding: .year, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                let lastNotificationValue = self.notificationEntries?.popLast()
                self.notificationEntries?.append((lastNotificationValue ?? 0) + thisEntry.znumberofnotifications)
                
                let lastPickupValue = self.pickupEntries?.popLast()
                self.pickupEntries?.append((lastPickupValue ?? 0) + thisEntry.znumberofpickups)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.notificationEntries?.append(0)
                self.pickupEntries?.append(0)
            }
        }
    }
    
    
    // MARK: handle delete
    @objc func deleteItemHandler() {
        let index = self.countedItemTable?.clickedRow
        if index ?? -1 < 0 {
            return
        }
        
        let deletingItem = self.countedItems?[index!]
        NotificationCenter.default.post(name: .STCCountedItemDelete, object: nil, userInfo: ["deletingItem": deletingItem!, "index": index!])
    }
    
    func deletionSuccess(of index: Int) {
        self.countedItems?.remove(at: index)
        if self.isViewLoaded && self.view.window != nil {
            self.countedItemTable?.reloadData()
            if let countedItems = self.countedItems {
                self.processChartData(countedItems: countedItems)
                self.processChart()
            }
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
    func changeSuccess(of index: Int, with newCountedItem: STCCountedItem) {
        self.countedItems![index] = newCountedItem
        if self.isViewLoaded && self.view.window != nil {
            self.countedItemTable?.reloadData()
            if let countedItems = self.countedItems {
                self.processChartData(countedItems: countedItems)
                self.processChart()
            }
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
        return self.countedItems?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let timeEntry = self.countedItems![row]
        var text = ""
        var identifier: NSUserInterfaceItemIdentifier
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        switch tableColumn?.identifier.rawValue {
        case "STCCountedItemTableStartTimeColumn":
            text = formatter.string(from: timeEntry.zstartdate)
            identifier = NSUserInterfaceItemIdentifier("STCCountedItemTableStartTime")
            
        case "STCCountedItemTableNotificationsColumn":
            text = String(timeEntry.znumberofnotifications)
            identifier = NSUserInterfaceItemIdentifier("STCCountedItemTableNotifications")
            
        case "STCCountedItemTablePickupsColumn":
            text = String(timeEntry.znumberofpickups)
            identifier = NSUserInterfaceItemIdentifier("STCCountedItemTablePickups")
            
        default:
            text = ""
            identifier = NSUserInterfaceItemIdentifier("")
        }
        
        if let view = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = text
            if tableColumn?.identifier.rawValue == "STCCountedItemTableNotifications" || tableColumn?.identifier.rawValue == "STCCountedItemTablePickups" {
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
        let index = self.countedItemTable?.clickedRow
        if menuItem.action == #selector(deleteItemHandler) && index ?? -1 >= 0 {
            return true
        }
        return false
    }
    
    // MARK: conform to NSTextFieldDelegate
    func controlTextDidEndEditing(_ obj: Notification) {
        let textField = obj.object as? NSTextField
        let row = self.countedItemTable?.row(for: textField!)
        let column = self.countedItemTable?.column(for: textField!)
        if row ?? -1 >= 0 && column ?? -1 >= 0 {
            var changingItem = self.countedItems![row!]
            let current = Int(textField?.intValue ?? 0)
            var previous = 0
            if column == 1 {
                previous = changingItem.znumberofnotifications
                
                if current != previous {
                    changingItem.znumberofnotifications = current
                    NotificationCenter.default.post(name: .STCCountedItemChange, object: nil, userInfo: ["changingItem": changingItem, "index": row!])
                }
            } else if column == 2 {
                previous = changingItem.znumberofpickups
                
                if current != previous {
                    changingItem.znumberofpickups = current
                    NotificationCenter.default.post(name: .STCCountedItemChange, object: nil, userInfo: ["changingItem": changingItem, "index": row!])
                }
            }
        }
    }
    
    func control(_ control: NSControl, didFailToFormatString string: String, errorDescription error: String?) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Error, please change your input.", comment: "")
        alert.informativeText = NSLocalizedString("Only supports integer not less than 0.", comment: "")
        let row = self.countedItemTable?.row(for: control)
        let column = self.countedItemTable?.column(for: control)
        alert.runModal()
        if row ?? -1 >= 0 && column ?? -1 >= 0 {
            var changingItem = self.countedItems![row!]
            var previous = 0
            if column == 1 {
                previous = changingItem.znumberofnotifications
            } else if column == 2 {
                previous = changingItem.znumberofpickups
            }
            let textField = control as? NSTextField
            textField?.stringValue = String(previous)
        }
        
        return false
    }
    
    // MARK: conform to IValueFormatter
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        return String(Int(value))
    }
    
    // MARK: conform to IAxisValueFormatter
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if (axis as? XAxis) != nil {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            switch self.currentDisplayUnit {
            case .hour:
                formatter.dateFormat = "HH"
                
            case .day:
                formatter.dateFormat = "MM-dd"
                
            case .week:
                formatter.dateFormat = "MM-dd"
                
            case .month:
                formatter.dateFormat = "MM"
                
            case .year:
                formatter.dateFormat = "yyyy"
            }
            return formatter.string(from: self.chartXEntries![Int(value)])
        }
        if (axis as? YAxis) != nil {
            return String(Int(value))
        }
        return ""
    }
    
}
