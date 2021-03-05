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
    
    var centralManager : CBCentralManager?
    private var peripherals: [BLObject] = []
    var delegate : BLScannerDelegate?
    var connectedPeripheral : CBPeripheral?
    private var informationToBeShared: [SharedData] = []

    let READ_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x03, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))
        
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
        @unknown default:
            fatalError()
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
        
        print("Discovered \(peripheral.name ?? "Uknown Device") at \(RSSI)")
        
        if(!peripherals.contains(BLObject(displayName: peripheral.name ?? "Uknown Device", RSSI: "\(RSSI)", peripheral: peripheral))) {
            peripherals.append(BLObject(displayName: peripheral.name ?? "Uknown Device", RSSI: "\(RSSI)", peripheral: peripheral))
            updateObjects()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    
        print("Connected to \(peripheral.name ?? "Uknown Device")")
        centralManager?.stopScan()
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectedPeripheral?.discoverServices(nil)
    }
   
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device.")")
        
        delegate?.didFindInfo("Failed to connect.")
    }


    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let response = "Hey there".data(using: .utf8)
        request.value = response
        peripheral.respond(to: request, withResult: .success)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite request: CBATTRequest) {
        print("Did receive write request.")
        let response = "Wrote.".data(using: .utf8)
        request.value = response
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheral(_ peripheral:CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            print("TRUE WRITING")
        }

    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            if error == nil {
                print("TRUE")
                if characteristic.uuid == READ_UUID && characteristic.isNotifying == true {
                    retrieveData(characteristic: characteristic)
                } else {
                    print("Status has not changed.")
                }
            }
        }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let errorService = error {
            print("Error: \(errorService)")
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let errorCharacteristics = error {
            print("Error: \(errorCharacteristics)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.read) {
                  print("\(characteristic.uuid): properties contains .read")
                }
                if characteristic.properties.contains(.notify) {
                  print("\(characteristic.uuid): properties contains .notify")
                }
                if characteristic.properties.contains(.write) {
                    print("\(characteristic.uuid): properties contains .write")
                }
                if characteristic.properties.contains(.writeWithoutResponse) {
                    print("\(characteristic.uuid): properties contains .writeWithoutResponse")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let errorCharacteristic = error {
            print("Error: \(errorCharacteristic)")
            return
        }

        if let charValue = characteristic.value {
                print("Characteristic UUID: \(characteristic.uuid), value: \(charValue)")
                informationToBeShared.append(SharedData(sharedUUID: characteristic.uuid, sharedValue: charValue))
        }
    }

    func retrieveData(characteristic: CBCharacteristic) {
        if let charValue = characteristic.value {
            informationToBeShared.append(SharedData(sharedUUID: characteristic.uuid, sharedValue: charValue))
        } else {
            informationToBeShared.append(SharedData(sharedUUID: characteristic.uuid))
        }
    }

    func getInformation() -> [SharedData] {
        return informationToBeShared
    }

    func deleteInformation() {
        informationToBeShared.removeAll()
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
