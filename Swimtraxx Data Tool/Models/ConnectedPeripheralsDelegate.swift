//
//  ConnectedPeripheralsDelegate.swift
//  Swimtraxx Data Tool
//
//  Created by Steve Rustom on 06/09/2021.
//  Copyright © 2021 Capetech. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Connected peripherals delegate
protocol ConnectedPeripheralsDelegate {
    /// Returns True if the scanner finds the CBPeripheral, False otherwise
    /// - Parameter object: CBPeripheral interested in
    func didFindObject(object: CBPeripheral) -> Bool

    /// Returns True if the CBPeripheral disappeared, False otherwise
    /// - Parameter object:  CBPeripheral interested in
    func didDisappear(object: CBPeripheral) -> Bool

    /// Updates the BLScanner
    /// - Parameter sender: BLScanner
    func update(_ sender: BLScanner)

    /// Displays information
    /// - Parameter value: Information to display
    func didFindInfo(_ value: String)
}
