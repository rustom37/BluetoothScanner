//
//  BLScannerDelegate.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import Foundation

protocol BLScannerDelegate {
    func didFindObject(object: BLObject) -> Bool
    func didDisappear(object: BLObject) -> Bool
    func update(_ sender: BLScanner)
}
