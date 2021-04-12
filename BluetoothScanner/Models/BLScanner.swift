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

/// BLScanner class
class BLScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager : CBCentralManager?
    private var peripherals: [BLObject] = []
    var delegate : BLScannerDelegate?
    var connectedPeripheral : CBPeripheral?
    private var informationToBeShared: [SharedData] = []
    var receivingData : MutableProperty<Bool> = MutableProperty(false)

    /// BLScanner initialization.
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// Displays the status of the central manager on the terminal.
    /// - Parameter central: CBCentralManager interested in
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

    /// Starts the scanning process for nearby peripherals.
    func startScan() {
        print("Now Scanning...")
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.stopScan()
        })
    }

    /// Stops the scanning process for nearby peripherals.
    func stopScan() {
        self.centralManager?.stopScan()
        print("Scan stopped!\nNumber of Peripherals found: \(peripherals.count)")
    }

    /// Tells the delegate the central manager discovered a peripheral while scanning for devices.
    /// - Parameters:
    ///   - central: The central manager that provides the update.
    ///   - peripheral: The discovered peripheral.
    ///   - advertisementData: A dictionary containing any advertisement data.
    ///   - RSSI: The current received signal strength indicator (RSSI) of the peripheral, in decibels.
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

    /// Tells the delegate that the central manager connected to a peripheral.
    /// - Parameters:
    ///   - central: The central manager that provides this information.
    ///   - peripheral: The now-connected peripheral.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    
        print("Connected to \(peripheral.name ?? "Uknown Device")")
        centralManager?.stopScan()
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectedPeripheral?.discoverServices(nil)
    }

    /// Tells the delegate the central manager failed to create a connection with a peripheral.
    /// - Parameters:
    ///   - central: The central manager that provides this information.
    ///   - peripheral: The peripheral that failed to connect.
    ///   - error: The cause of the failure, or nil if no error occurred.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device.")")
        
        delegate?.didFindInfo("Failed to connect.")
    }

    /// Tells the delegate that the peripheral successfully set a value for the characteristic.
    /// - Parameters:
    ///   - peripheral: The peripheral providing this information.
    ///   - characteristic: The characteristic containing the value.
    ///   - error: The reason the call failed, or nil if no error occurred.
    func peripheral(_ peripheral:CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            print("TRUE WRITING")
            receivingData.value = true
        }

    }

    /// Tells the delegate that the peripheral received a request to start or stop providing notifications for a specified characteristic’s value.
    /// - Parameters:
    ///   - peripheral: The peripheral providing this information.
    ///   - characteristic: The characteristic for which to configure value notifications.
    ///   - error: The reason the call failed, or nil if no error occurred.
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            if error == nil {
                print("TRUE")
            }
        }

    /// Tells the delegate that peripheral service discovery succeeded.
    /// - Parameters:
    ///   - peripheral: The peripheral to which the services belong.
    ///   - error: The reason the call failed, or nil if no error occurred.
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

    /// Tells the delegate that the peripheral found characteristics for a service.
    /// - Parameters:
    ///   - peripheral: The peripheral providing this information.
    ///   - service: The service to which the characteristics belong.
    ///   - error: The reason the call failed, or nil if no error occurred.
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

    /// Tells the delegate that retrieving the specified characteristic’s value succeeded, or that the characteristic’s value changed.
    /// - Parameters:
    ///   - peripheral: The peripheral providing this information.
    ///   - characteristic: The characteristic containing the value.
    ///   - error: The reason the call failed, or nil if no error occurred.
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

    /// Retrieves the information that needs to be shared.
    /// - Returns: List of shared data from the flash of the peripheral
    func getInformation() -> [SharedData] {
        return informationToBeShared
    }

    /// Deletes all the data in the list of shared flash data.
    func deleteInformation() {
        informationToBeShared.removeAll()
    }

    /// Retrieves all the visible BLObjects in range.
    /// - Returns: List of BLObjects in range
    func getVisibleObjects() -> [BLObject] {
        return peripherals
    }

    /// Displays the available BLObjects
    func displayObjects() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.updateObjects()
            }
        }
    }

    /// Updates the delegate
    func updateObjects() {
        delegate?.update(self)
    }
}

extension Data {
    /// HexEncoding structure
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    /// Converts a Hex structure into a String.
    /// - Parameter options: List of HexEncodings that needs to be converted
    /// - Returns: Correct String representation of the HexEncodings
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
