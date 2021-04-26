//
//  BLobject.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Class representation of the BLObject
class BLObject : Equatable {

    /// BLObject is equatable.
    /// - Parameters:
    ///   - lhs: BLObject on the left hand side
    ///   - rhs: BLObject on the right hand side
    /// - Returns: True if the lhs and rhs are equal, False otherwise
    static func == (lhs: BLObject, rhs: BLObject) -> Bool {
        guard type(of: lhs) == type(of: rhs) else { return false }
        return lhs.displayName == rhs.displayName
    }
    
    
    let displayName : String?
    let RSSI : String?
    let peripheral : CBPeripheral?

    /// BLObject initialization
    /// - Parameters:
    ///   - displayName: Displayed name of the BLObject
    ///   - RSSI: RSSI of the BLObject
    ///   - peripheral: CBPeripheral of the BLObject
    init(displayName: String, RSSI: String, peripheral: CBPeripheral) {
        self.displayName = displayName
        self.RSSI = RSSI
        self.peripheral = peripheral
    }
}
