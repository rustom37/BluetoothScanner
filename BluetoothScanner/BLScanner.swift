//
//  BLScanner.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class BLScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager : CBCentralManager?
    private var peripherals: [BLObject] = []
    var delegate : BLScannerDelegate?

        
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Central state is unknown.")
        case .resetting:
            print("Central state is resetting.")
        case .unsupported:
            print("Central state is unsupported.")
        case .unauthorized:
            print("Central state is unauthorized.")
        case .poweredOff:
            print("Central state is powered off.")
            centralManager?.stopScan()
        case .poweredOn:
            print("Central state is powered on.")
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    func startScan() {
        print("Now Scanning...")
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.stopScan()
        })
    }
    
    func stopScan() {
        self.centralManager?.stopScan()
        print("Scan stopped!\nNumber of Peripherals found: \(peripherals.count)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if  RSSI.intValue < -15 && RSSI.intValue > -35 {
            print("Device not at correct range")
            return
        }
        
        print("Discovered \(peripheral.name ?? "no name") at \(RSSI)")
        
        if(!peripherals.contains(BLObject(displayName: peripheral.name ?? "no name", RSSI: "\(RSSI)", peripheral: peripheral))) {
            peripherals.append(BLObject(displayName: peripheral.name ?? "No Name", RSSI: "\(RSSI)", peripheral: peripheral))
            updateObjects()
        }
    }
    
    func getVisibleObjects() -> [BLObject] {
        return peripherals
    }
    
    func displayObjects() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.updateObjects()
            }
        }
    }
    
    func updateObjects() {
        delegate?.update(self)
    }
}
