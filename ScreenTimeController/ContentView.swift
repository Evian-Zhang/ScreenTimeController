//
//  ContentView.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/25.
//  Copyright © 2019 Evian张. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    var timeEntries: Array<STCTimedItem>
    var body: some View {
        List(0 ..< timeEntries.count) { index in
            TimeItemRow(timeEntry: self.timeEntries[index])
        }
    }
}

struct TimeItemRow : View {
    var timeEntry: STCTimedItem
    var body: some View {
        HStack {
            Text(String(timeEntry.ztotaltimeinseconds))
            Divider()
            Text(timeEntry.zstartdate.description)
        }
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(countedItems: [STCTimedItem(z_pk: 0, ztotaltimeinseconds: 0, zblock: 0, zcategory: 0, zstartdate: Date()), STCTimedItem(z_pk: 0, ztotaltimeinseconds: 100, zblock: 0, zcategory: 0, zstartdate: Date())])
            .environment(\.colorScheme, .dark)
    }
}
#endif
