//
//  BLobject.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLObject : Equatable {
    static func == (lhs: BLObject, rhs: BLObject) -> Bool {
        guard type(of: lhs) == type(of: rhs) else { return false }
        return lhs.displayName == rhs.displayName
    }
    
    
    let displayName : String?
    let RSSI : String?
    let peripheral : CBPeripheral?
    
    init(displayName: String, RSSI: String, peripheral: CBPeripheral) {
        self.displayName = displayName
        self.RSSI = RSSI
        self.peripheral = peripheral
    }
}
