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
    var doorPeripheral : CBPeripheral?
        
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
        doorPeripheral = peripheral
        doorPeripheral?.delegate = self
        doorPeripheral?.discoverServices(nil)
    }
   
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device.")")
        
        delegate?.didFindInfo("Failed to connect.")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        var i = 1
        
        if let errorService = error {
            print("Error: \(errorService)")
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                print("\(i). Service: Discover service \(service)")
                print("Service UUID: \(service.uuid) ")
                
                i += 1
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
        print("///////////////////////////////////////////////////////////")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let errorCharacteristics = error {
            print("Error: \(errorCharacteristics)")
            return
        }
        
        if let characteristics = service.characteristics {
            
            print("Found \(characteristics.count) characteristic(s)!")
            
            for characteristic in characteristics {
                print("Char: service \(service.uuid) Discover char \(characteristic)")
                print("Char UUID: \(characteristic.uuid)")
                
                if(characteristic.properties == CBCharacteristicProperties.read) {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let errorCharacteristic = error {
            print("Error: \(errorCharacteristic)")
            return
        }
        
        var valueString = String(data:characteristic.value!, encoding: .utf8)
        if let valueString = valueString {
            delegate?.didFindInfo(valueString)
        } else {
            delegate?.didFindInfo("NO DATA FOUND")
        }
        print("Characteristic UUID: \(characteristic.uuid), value: \(String(describing: characteristic.value ?? Data(base64Encoded: "Unknown Value."))), and ValueString: \(valueString ?? "Unknown Value String.")")
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
