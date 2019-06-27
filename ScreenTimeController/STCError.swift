//
//  STCError.swift
//  ScreenTimeController
//
//  Created by Evian张 on 2019/6/27.
//  Copyright © 2019 Evian张. All rights reserved.
//

import Foundation

enum STCDataModelError: Error {
    case executableNotExist
    case fileNotExist
    case connectionFail
    case unknown
}
