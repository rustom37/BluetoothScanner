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
import AVFoundation

/// BLScanner class
class BLScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    static let shared = BLScanner()
    
    var centralManager : CBCentralManager?
    private var peripherals: [BLObject] = []
    var delegate : BLScannerDelegate?
    var connectedDelegate : ConnectedPeripheralsDelegate?
    private var connectedPeripherals = [String : CBPeripheral]()
    private var peripheralsInfoToBeShared = [String : [String]]()
    private var peripheralsRemainder = [String: String]()
    private var retrievingData = [String : MutableProperty<Bool>]()
    private var player: AVAudioPlayer?
    var changeIsHappening = MutableProperty<Bool>(false)

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
            stopScan()
        case .poweredOn:
            print("Central state is powered on.")
            startScan()
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
        connectedPeripherals[peripheral.identifier.uuidString] = peripheral
        peripheralsRemainder[peripheral.identifier.uuidString] = ""
        retrievingData[peripheral.identifier.uuidString] = MutableProperty(false)
        if let connectedPeripheral = connectedPeripherals[peripheral.identifier.uuidString] {
            connectedPeripheral.delegate = self
            connectedPeripheral.discoverServices(nil)
        }
        updateConnectedObjects()
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
            retrievingData.updateValue(MutableProperty(true), forKey: peripheral.identifier.uuidString)
            changeIsHappening.value = true
        }

    }

    /// Tells the delegate that the peripheral received a request to start or stop providing notifications for a specified characteristic’s value.
    /// - Parameters:
    ///   - peripheral: The peripheral providing this information.
    ///   - characteristic: The characteristic for which to configure value notifications.
    ///   - error: The reason the call failed, or nil if no error occurred.
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }

        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == TransferService.WRITE_UUID else { return }

        if characteristic.isNotifying {
            // Notification has started
            print("Notification began on \(characteristic)")
        } else {
            // Notification has stopped, so disconnect from the peripheral
            print("Notification stopped on \(characteristic). Disconnecting")
            cleanup(connectedPeripheral: peripheral)
        }
    }

    /// Tells the delegate that peripheral service discovery succeeded.
    /// - Parameters:
    ///   - peripheral: The peripheral to which the services belong.
    ///   - error: The reason the call failed, or nil if no error occurred.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let errorService = error {
            print("Error discovering services: \(errorService)")
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
            print("Error discovering characteristics: \(errorCharacteristics)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == TransferService.NOTIFY_UUID {
                    print("\(characteristic.uuid): properties contains .notify")
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == TransferService.WRITE_UUID {
                    print("\(characteristic.uuid): properties contains .write")
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
            print("Error updating value: \(errorCharacteristic)")
            cleanup(connectedPeripheral: peripheral)
            return
        }

        var tempList: [String]
        if let charValue = characteristic.value {
            if (charValue.hexEncodedString() != "17000000") && !(charValue.bytes.first == 255 && charValue.bytes.allEqual()) {
                print("Peripheral Name: \(peripheral.name ?? "Unknown Device"), value: \(charValue.hexEncodedString())")
                if peripheralsInfoToBeShared.keys.contains(peripheral.identifier.uuidString) {
                    tempList = peripheralsInfoToBeShared[peripheral.identifier.uuidString]!
                } else {
                    tempList = []
                }
                if let remainder = peripheralsRemainder[peripheral.identifier.uuidString] {
                    // Split the data equally
                    var dividedData = split(myString: charValue.hexEncodedString(), by: 32, remainder: remainder)

                    if let firstData = dividedData.first {
                        dividedData[0] = remainder + firstData // append the remainder to the first of element of the data
                    }

                    if let lastData = dividedData.last {
                        // If the data is not split equally
                        if lastData.length != 32 {
                            peripheralsRemainder.updateValue(lastData, forKey: peripheral.identifier.uuidString) // Set the remainder as the last element of the divided data
                            dividedData.removeLast()
                        } else {
                            peripheralsRemainder.updateValue("", forKey: peripheral.identifier.uuidString)
                        }
                    }
                    for divData in dividedData {
                        if divData != "ffffffffffffffffffffffffffffffff" {
                            tempList.append(divData)
                        }
                    }

                    if peripheralsInfoToBeShared.keys.contains(peripheral.identifier.uuidString) {
                        peripheralsInfoToBeShared.updateValue(tempList, forKey: peripheral.identifier.uuidString)
                    } else {
                        peripheralsInfoToBeShared[peripheral.identifier.uuidString] = tempList
                        print("creating new list")
                    }
                }

                if charValue.bytes.containsContinuousValue(value: 255, forMinimumRepeats: 16) {
                    print("\(peripheral.name ?? "Unknown Device") is DONE.")
                    retrievingData.updateValue(MutableProperty(false), forKey: peripheral.identifier.uuidString)
                    changeIsHappening.value = false
                    peripheral.setNotifyValue(false, for: characteristic)
                    playSound()
                }
            }
        }
    }

    /// Call this when things either go wrong, or you're done with the connection.
    /// This cancels any subscriptions if there are any, or straight disconnects if not.
    /// (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
    /// - Parameter peripheral: The peripheral providing this information.
    private func cleanup(connectedPeripheral: CBPeripheral) {
        // Don't do anything if we're not connected
        if  !(connectedPeripheral.state == .connected) {
            return
        }

        for service in (connectedPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) where (characteristic.uuid == TransferService.WRITE_UUID && characteristic.isNotifying) {
                    // It is notifying, so unsubscribe
                    connectedPeripheral.setNotifyValue(false, for: characteristic)
            }
        }

        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager?.cancelPeripheralConnection(connectedPeripheral)
    }

    /// Retrieves the information that needs to be shared.
    /// - Returns: List of shared data from the flash of the peripheral
    func getInformation(uuid: String) -> [String] {
        return peripheralsInfoToBeShared[uuid] ?? []
    }
    
    func getAllInformation() -> [String : [String]] {
        return peripheralsInfoToBeShared
    }

    func areAllInfoEmpty() -> Bool {
        for (_,list) in peripheralsInfoToBeShared {
            if !list.isEmpty {
                return false
            }
        }
        return true
    }

    /// Deletes all the data in the list of shared flash data.
    func deleteInformation(uuid: String) {
        peripheralsInfoToBeShared[uuid]?.removeAll()
    }

    func deleteAllInformation() {
        for var (_, list) in peripheralsInfoToBeShared {
            list.removeAll()
        }
    }

    /// Retrieves all the visible BLObjects in range.
    /// - Returns: List of BLObjects in range
    func getVisibleObjects() -> [BLObject] {
        return peripherals
    }

    /// Retrieves all the connected CBPeripherals.
    /// - Returns: Dictionary of connected CBPeripherals
    func getConnectedObjects() -> [String : CBPeripheral] {
        return connectedPeripherals
    }

    func getConnectedObjectsKeys() -> [String] {
        return Array(connectedPeripherals.keys)
    }

    /// Retrieves all the retrieval statuses of connected peripherals
    /// - Returns: Dictionary of retrieval statuses
    func getRetrievalStatus() -> [String : MutableProperty<Bool>] {
        return retrievingData
    }

    func getRetrievalStatusKeys() -> [String] {
        return Array(retrievingData.keys)
    }

    /// Displays the available BLObjects
    func displayObjects() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.updateObjects()
            }
        }
    }

    /// Displays the connected BLObjects
    func displayConnectedObjects() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.updateConnectedObjects()
            }
        }
    }

    /// Updates the delegate
    func updateObjects() {
        delegate?.update(self)
    }

    /// Updates the connectedDelegate
    func updateConnectedObjects() {
        connectedDelegate?.update(self)
    }

    private func playSound() {
        guard let url = Bundle.main.url(forResource: "splash", withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            guard let player = player else { return }
            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }

    private func split(myString: String, by length: Int, remainder: String) -> [String] {
        var startIndex = myString.startIndex
        var results = [Substring]()
        if remainder.length == 0 {
            while startIndex < myString.endIndex {
                let endIndex = myString.index(startIndex, offsetBy: length, limitedBy: myString.endIndex) ?? myString.endIndex
                results.append(myString[startIndex..<endIndex])
                startIndex = endIndex
            }

            return results.map { String($0) }
        } else {
            while startIndex < myString.endIndex {
                let index: Int = myString.distance(from: myString.startIndex, to: startIndex)
                if index == 0 {
                    let endIndex = myString.index(startIndex, offsetBy: (length-remainder.length), limitedBy: myString.endIndex) ?? myString.endIndex
                    results.append(myString[startIndex..<endIndex])
                    startIndex = endIndex
                } else {
                    let endIndex = myString.index(startIndex, offsetBy: length, limitedBy: myString.endIndex) ?? myString.endIndex
                    results.append(myString[startIndex..<endIndex])
                    startIndex = endIndex
                }
            }
            return results.map { String($0) }
        }
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

///  Groups successive elements in tuples (value, numberOfSuccessions)
extension Sequence where Iterator.Element: Equatable {
    func group() -> [(Iterator.Element, Int)] {
        var res: [(Iterator.Element, Int)] = []
        for el in self {
            if res.last?.0 == el {
                res[res.endIndex-1].1 += 1
            } else {
                res.append((el,1))
            }
        }
        return res
    }
}

extension Sequence where Iterator.Element == UInt8 {
    func containsContinuousValue(value: UInt8, forMinimumRepeats rep: Int) -> Bool {
        return self.group().contains{ (val, count) in count >= rep && val == value }
    }
}

/// Check if all elements of an array have the same value
extension Array where Element : Equatable {
    func allEqual() -> Bool {
        if let firstElem = first {
            return !dropFirst().contains { $0 != firstElem }
        }
        return true
    }
}
