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
    @IBOutlet var barChartView: BarChartView?
    @IBOutlet var chartDisplayPopUpButton: NSPopUpButton?

    var countedItems: Array<STCCountedItem>?
    var chartXEntries: Array<Date>?
    var chartYEntries: Array<STCTimeUnit>?
    var currentDisplayUnit = STCDisplayUnit.day
    
    let barWidth = 0.4
    let barSpace = 0.05
    let barChartDataSetColor = NSColor.red
    
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
        
        self.barChartView?.doubleTapToZoomEnabled = false
        self.barChartView?.highlightPerTapEnabled = false
        self.barChartView?.gridBackgroundColor = .white
        self.barChartView?.legend.enabled = false
        self.barChartView?.xAxis.labelPosition = .bottom
        self.barChartView?.xAxis.valueFormatter = self
        self.barChartView?.xAxis.labelTextColor = .textColor
        self.barChartView?.leftAxis.valueFormatter = self
        self.barChartView?.leftAxis.labelTextColor = .textColor
        self.barChartView?.rightAxis.valueFormatter = self
        self.barChartView?.rightAxis.labelTextColor = .textColor
        self.barChartView?.noDataTextColor = .textColor
        self.barChartView?.noDataText = NSLocalizedString("No data Available", comment: "")
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
        var barChartDataEntries = Array<BarChartDataEntry>()
        for index in 0 ..< (self.chartYEntries?.count)! {
            barChartDataEntries.append(BarChartDataEntry(x: Double(index), y: self.chartYEntries![index].doubleValue()))
        }
        let barChartData = BarChartData()
        let barChartDataSet = BarChartDataSet(entries: barChartDataEntries)
        barChartDataSet.colors = [self.barChartDataSetColor]
        barChartData.addDataSet(barChartDataSet)
        
        barChartData.barWidth = self.barWidth
        barChartData.setValueFormatter(self)
        barChartData.setValueTextColor(.textColor)
        self.barChartView?.data = barChartData
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
                self.barChartView?.needsDisplay = true
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
    func prepareForHour(of timeEntries: Array<STCTimedItem>) {
        if (timeEntries.count == 0) {
            return
        }
        
        let firstHourRaw = (timeEntries.first?.zstartdate)!
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: firstHourRaw)
        let firstHour = calendar.date(from: components)
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstHour!)
        self.chartYEntries = Array<STCTimeUnit>()
        self.chartYEntries?.append(STCTimeUnit())
        var index = 0
        while index < timeEntries.count {
            let thisEntry = timeEntries[index]
            let nextUnit = calendar.date(byAdding: .hour, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                self.chartYEntries?.last?.addSecond(second: thisEntry.ztotaltimeinseconds)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.chartYEntries?.append(STCTimeUnit())
            }
        }
    }
    
    func prepareForDay(of timeEntries: Array<STCTimedItem>) {
        if (timeEntries.count == 0) {
            return
        }
        
        let firstDateRaw = timeEntries.first?.zstartdate
        let calendar = Calendar.current
        let firstDate = calendar.startOfDay(for: firstDateRaw ?? Date())
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstDate)
        self.chartYEntries = Array<STCTimeUnit>()
        self.chartYEntries?.append(STCTimeUnit())
        var index = 0
        while index < timeEntries.count {
            let thisEntry = timeEntries[index]
            let nextUnit = calendar.date(byAdding: .day, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                self.chartYEntries?.last?.addSecond(second: thisEntry.ztotaltimeinseconds)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.chartYEntries?.append(STCTimeUnit())
            }
        }
    }
    
    func prepareForWeek(of timeEntries: Array<STCTimedItem>) {
        if (timeEntries.count == 0) {
            return
        }
        
        let firstWeekRaw = timeEntries.first?.zstartdate
        let calendar = Calendar.current
        let thisDay = calendar.startOfDay(for: firstWeekRaw!)
        let firstWeek = calendar.date(bySetting: .weekday, value: 1, of: thisDay)
        
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstWeek!)
        self.chartYEntries = Array<STCTimeUnit>()
        self.chartYEntries?.append(STCTimeUnit())
        var index = 0
        while index < timeEntries.count {
            let thisEntry = timeEntries[index]
            let nextUnit = calendar.date(byAdding: .weekOfYear, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                self.chartYEntries?.last?.addSecond(second: thisEntry.ztotaltimeinseconds)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.chartYEntries?.append(STCTimeUnit())
            }
        }
    }
    
    func prepareForMonth(of timeEntries: Array<STCTimedItem>) {
        if (timeEntries.count == 0) {
            return
        }
        
        let firstMonthRaw = timeEntries.first?.zstartdate
        let calendar = Calendar.current
        let thisDay = calendar.startOfDay(for: firstMonthRaw!)
        let firstMonth = calendar.date(bySetting: .day, value: 1, of: thisDay)
        
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstMonth!)
        self.chartYEntries = Array<STCTimeUnit>()
        self.chartYEntries?.append(STCTimeUnit())
        var index = 0
        while index < timeEntries.count {
            let thisEntry = timeEntries[index]
            let nextUnit = calendar.date(byAdding: .month, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                self.chartYEntries?.last?.addSecond(second: thisEntry.ztotaltimeinseconds)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.chartYEntries?.append(STCTimeUnit())
            }
        }
    }
    
    func prepareForYear(of timeEntries: Array<STCTimedItem>) {
        if (timeEntries.count == 0) {
            return
        }
        
        let firstYearRaw = timeEntries.first?.zstartdate
        let calendar = Calendar.current
        let thisDay = calendar.startOfDay(for: firstYearRaw!)
        let firstYear = calendar.date(from: calendar.dateComponents([.year], from: thisDay))
        
        self.chartXEntries = Array<Date>()
        self.chartXEntries?.append(firstYear!)
        self.chartYEntries = Array<STCTimeUnit>()
        self.chartYEntries?.append(STCTimeUnit())
        var index = 0
        while index < timeEntries.count {
            let thisEntry = timeEntries[index]
            let nextUnit = calendar.date(byAdding: .year, value: 1, to: (self.chartXEntries?.last)!)!
            if thisEntry.zstartdate.compare(nextUnit) == .orderedAscending {
                self.chartYEntries?.last?.addSecond(second: thisEntry.ztotaltimeinseconds)
                index += 1
            } else {
                self.chartXEntries?.append(nextUnit)
                self.chartYEntries?.append(STCTimeUnit())
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
                    NotificationCenter.default.post(name: .STCScreenTimeChange, object: nil, userInfo: ["changingItem": changingItem, "index": row!])
                }
            } else if column == 2 {
                previous = changingItem.znumberofpickups
                
                if current != previous {
                    changingItem.znumberofpickups = current
                    NotificationCenter.default.post(name: .STCScreenTimeChange, object: nil, userInfo: ["changingItem": changingItem, "index": row!])
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
        return STCTimeUnit.timeUnit(of: value).stringValue()
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
            return STCTimeUnit.timeUnit(of: value).stringValue()
        }
        return ""
    }
    
}
