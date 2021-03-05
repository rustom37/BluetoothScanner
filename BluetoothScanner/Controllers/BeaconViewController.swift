//
//  BeaconViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 24/02/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import UIKit
import CoreBluetooth

class BeaconViewController: UIViewController, CBPeripheralDelegate {

    @IBOutlet weak var shareButton: UIButton!

    var peripheral: CBPeripheral?
    var charachteristicsArray: [CBCharacteristic]?
    var informationArray: [SharedData]?
    var stringToBeShared: String =  ""
    var availableScanner: BLScanner?

    let NUS_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x01, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))
    let WRITE_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x02, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))
    let READ_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x03, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        peripheral?.delegate  = self

        self.title = "\(peripheral?.name ?? "Unknown Device")."

        shareButton.isEnabled = false

        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
    }

    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .down {
            print("Swipe down")
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func receiveDataPressed(_ sender: Any) {
        if let services = peripheral?.services {
            for service in services {
                if  service.uuid == NUS_UUID {
                    if let characteristics  = service.characteristics {
                        for characteristic in characteristics {
                            if characteristic.uuid == READ_UUID && characteristic.properties.contains(.notify) {
                                print("Receiving Data...")
                                peripheral?.setNotifyValue(true, for: characteristic)
                            }
                        }
                    }
                }
            }
        }
        shareButton.isEnabled = true
    }

    @IBAction func writeDataPressed(_ sender: Any) {
        if let services = peripheral?.services {
            for service in services {
                if service.uuid == NUS_UUID {
                    if let characteristics = service.characteristics {
                        for characteristic in characteristics {
                            if characteristic.uuid == WRITE_UUID && characteristic.properties.contains(.write) {
                                print("Writing data without response...")
                                peripheral?.writeValue(Data([0x01]), for: characteristic, type: CBCharacteristicWriteType.withResponse)
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func shareButtonPressed(_ sender: Any) {
        if let scanner = availableScanner {
            for data in scanner.getInformation() {
                stringToBeShared += "Characteristic UUID:  \(data.sharedUUID)\n=> Value: \(data.sharedValue)\n---------------------\n"
            }
        }
        let items = [stringToBeShared]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
}
