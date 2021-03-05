//
//  SharedData.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 05/03/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import Foundation
import CoreBluetooth

class SharedData {
    let sharedUUID: CBUUID
    let sharedValue: Data

    init(sharedUUID: CBUUID, sharedValue: Data) {
        self.sharedUUID = sharedUUID
        self.sharedValue = sharedValue
    }

    init(sharedUUID: CBUUID) {
        self.sharedUUID = sharedUUID
        sharedValue = Data()
    }
    
}
