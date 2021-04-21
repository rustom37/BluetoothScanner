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

/// View controller that displays  the connected peripheral.
class BeaconViewController: UIViewController, CBPeripheralDelegate {

    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var plotButton: UIButton!

    var peripheral: CBPeripheral?
    var stringToBeShared: String =  ""
    var availableScanner: BLScanner = BLScanner()

    let NUS_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x01, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))
    let WRITE_UUID: CBUUID = CBUUID(data: Data([0x6E, 0x40, 0x00, 0x02, 0xB5, 0xA3, 0xF3, 0x93, 0xE0, 0xA9, 0xE5, 0x0E, 0x24, 0xDC, 0xCA, 0xBE]))

    /// Loads the view
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
        self.plotButton.reactive.isEnabled <~ (availableScanner.receivingData.producer.map { value in
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

    /// When pressed on the retrieve data from flash button, data retrieval from flash begins
    /// - Parameter sender: Any touch on button
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

    /// When pressed on the share data button, data gets shared
    /// - Parameter sender: Any touch on button
    @IBAction func shareButtonPressed(_ sender: Any) {
        var arr = availableScanner.getInformation()
        arr.removeFirst()
        arr.removeLast()
        let alert = UIAlertController(title: "Share Content", message: "Please Select an Option", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Original File", style: .default , handler:{ (UIAlertAction) in
            print("User click Original File button")
            for data in arr {
                self.stringToBeShared += "\(data.sharedValue.hexEncodedString())\n"
            }
            let items = [self.stringToBeShared]
            self.stringToBeShared = ""
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(ac, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Unprocessed File", style: .default , handler:{ (UIAlertAction) in
            print("User click Unprocessed File button")
            for data in arr {
                if !(data.sharedValue.starts(with: [0x08])) {
                    self.stringToBeShared += "\(data.sharedValue.hexEncodedString())\n"
                }
            }
            let items = [self.stringToBeShared]
            self.stringToBeShared = ""
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(ac, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Processed File", style: .default , handler:{ (UIAlertAction) in
            print("User click Processed File button")
            for data in arr {
                if data.sharedValue.starts(with: [0x08]) {
                    self.stringToBeShared += "\(data.sharedValue.hexEncodedString())\n"
                }
            }
            let items = [self.stringToBeShared]
            self.stringToBeShared = ""
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(ac, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction) in
            print("User click Dismiss button")
        }))

        // For iPad Support
        alert.popoverPresentationController?.sourceView = self.view

        self.present(alert, animated: true, completion: {
            print("Completion block")
        })
    }

    /// Plots the data when pressed
    /// - Parameter sender: Any touch on button
    @IBAction func plotButtonPressed(_ sender: Any) {
        var arr = availableScanner.getInformation()
        arr.removeFirst()
        arr.removeLast()
        var arrData: [String] = []
        for data in arr {
            if !(data.sharedValue.starts(with: [0x08])) {
                arrData.append("\(data.sharedValue.hexEncodedString())")
            }
        }
        let (sensorDataMultipleMeasurements,_) = decodeData(rawData: arrData)
        UserDefaults.standard.setValue(sensorDataMultipleMeasurements, forKey: "dataArray")

        let vc: PlotMeasurementsViewController = self.storyboard?.instantiateViewController(withIdentifier: "PlotMeasurementsViewController") as! PlotMeasurementsViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
