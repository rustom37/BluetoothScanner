//
//  BLScannerDelegate.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import Foundation

/// BLScanner delegate
protocol BLScannerDelegate {
    /// Returns True if the scanner finds the BLObject, False otherwise
    /// - Parameter object: BLObject interested in
    func didFindObject(object: BLObject) -> Bool

    /// Returns True if the BLObject disappeared, False otherwise
    /// - Parameter object:  BLObject interested in
    func didDisappear(object: BLObject) -> Bool

    /// Updates the BLScanner
    /// - Parameter sender: BLScanner
    func update(_ sender: BLScanner)

    /// Displays information
    /// - Parameter value: Information to display 
    func didFindInfo(_ value: String)
}
