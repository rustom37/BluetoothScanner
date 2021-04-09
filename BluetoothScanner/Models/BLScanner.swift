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
import ReactiveCocoa
import ReactiveSwift

class BLScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager : CBCentralManager?
    private var peripherals: [BLObject] = []
    var delegate : BLScannerDelegate?
    var connectedPeripheral : CBPeripheral?
    private var informationToBeShared: [SharedData] = []
    var receivingData : MutableProperty<Bool> = MutableProperty(false)

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

    func peripheral(_ peripheral:CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            print("TRUE WRITING")
            receivingData.value = true
        }

    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            if error == nil {
                print("TRUE")
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
                  print("Receiving Data...")
                  peripheral.setNotifyValue(true, for: characteristic)
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
            if charValue.hexEncodedString() == "ffffffffffffffffffffffffffffffff" {
                print("Done.")
                receivingData.value = false
            } else {
                print("Characteristic UUID: \(characteristic.uuid), value: \(charValue.hexEncodedString())")
                informationToBeShared.append(SharedData(sharedUUID: characteristic.uuid, sharedValue: charValue))
            }
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

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
