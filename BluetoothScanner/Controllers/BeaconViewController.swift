//
//  BeaconViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 24/02/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import UIKit
import CoreBluetooth
import ReactiveCocoa
import ReactiveSwift

class BeaconViewController: UIViewController, CBPeripheralDelegate {

    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!

    var peripheral: CBPeripheral?
    var stringToBeShared: String =  ""
    var availableScanner: BLScanner = BLScanner()

    let NUS_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x01, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))
    let WRITE_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x02, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        peripheral?.delegate  = self
        loadingSpinner.hidesWhenStopped = true
        self.title = "\(peripheral?.name ?? "Unknown Device")."
        self.shareButton.reactive.isEnabled <~ (availableScanner.receivingData.producer.map { value in
            if (value == false) && (self.availableScanner.getInformation().isEmpty) {
                return false
            } else if (value == false) && !(self.availableScanner.getInformation().isEmpty) {
                return true
            } else {
                return false
            }
        })
        self.loadingSpinner.reactive.isAnimating <~ (availableScanner.receivingData.producer.map { value in return value ? true : false })
    }

    @IBAction func writeDataPressed(_ sender: Any) {
        if let services = peripheral?.services {
            for service in services {
                if service.uuid == NUS_UUID {
                    if let characteristics = service.characteristics {
                        for characteristic in characteristics {
                            if characteristic.uuid == WRITE_UUID && characteristic.properties.contains(.write) {
                                print("Writing data without response...")
                                peripheral?.writeValue(Data([0x17]), for: characteristic, type: CBCharacteristicWriteType.withResponse)
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func shareButtonPressed(_ sender: Any) {
        var arr = availableScanner.getInformation()
        arr.removeFirst()
        arr.removeLast()
        for data in arr {
            stringToBeShared += "\(data.sharedValue.hexEncodedString())\n"
        }
        availableScanner.deleteInformation()
        let items = [stringToBeShared]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
}
