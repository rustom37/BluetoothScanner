//
//  SharedData.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 05/03/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import Foundation
import CoreBluetooth

/// SharedData class
class SharedData {
    let sharedUUID: CBUUID
    let sharedValue: Data

    /// SharedData initialization
    /// - Parameters:
    ///   - sharedUUID: The UUID of the characteristic that is being shared via BLE
    ///   - sharedValue: The actual Data of the characteristic that is being shared via BLE
    init(sharedUUID: CBUUID, sharedValue: Data) {
        self.sharedUUID = sharedUUID
        self.sharedValue = sharedValue
    }

    /// SharedData initialization
    /// - Parameter sharedUUID: The UUID of the characteristic that is being shared via BLE
    init(sharedUUID: CBUUID) {
        self.sharedUUID = sharedUUID
        sharedValue = Data()
    }
    
}
