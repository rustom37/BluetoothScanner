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
class BeaconViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ConnectedPeripheralsDelegate {

    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var plotButton: UIButton!

    var stringToBeShared: String =  ""
    var pressedUUID: UUID?
    var isPressedUUIDNil: MutableProperty<Bool> = MutableProperty(true)

    /// Loads the view
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(UINib(nibName: "CustomTableViewCell", bundle: nil),  forCellReuseIdentifier: "customTableViewCell")
        BLScanner.shared.connectedDelegate = self
        configureTableView()
        BLScanner.shared.displayConnectedObjects()

        self.title = "Connected Device(s)"

        self.shareButton.reactive.isEnabled <~ (isPressedUUIDNil.producer.map { value in
            if let uuid = self.pressedUUID?.uuidString {
                if (value == false) && (BLScanner.shared.getInformation(uuid: uuid).isEmpty) {
                    return false
                } else if (value == false) && !(BLScanner.shared.getInformation(uuid: uuid).isEmpty) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        })
        self.plotButton.reactive.isEnabled <~ (isPressedUUIDNil.producer.map { value in
            if let uuid = self.pressedUUID?.uuidString {
                if (value == false) && (BLScanner.shared.getInformation(uuid: uuid).isEmpty) {
                    return false
                } else if (value == false) && !(BLScanner.shared.getInformation(uuid: uuid).isEmpty) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        })

        self.tableView.reactive.reloadData <~ BLScanner.shared.changeIsHappening.producer.map { value in
            if value {
                self.tableView.reloadData()
            } else {
                self.tableView.reloadData()
            }
        }
    }

    /// When pressed on the retrieve data from flash button, data retrieval from flash begins
    /// - Parameter sender: Any touch on button
    @IBAction func writeDataPressed(_ sender: Any) {
        let peripherals = Array(BLScanner.shared.getConnectedObjects().values)

        DispatchQueue.concurrentPerform(iterations: peripherals.count) { index in
            if let services = peripherals[index].services {
                for service in services {
                    if service.uuid == TransferService.NUS_UUID {
                        if let characteristics = service.characteristics {
                            for characteristic in characteristics where (characteristic.uuid == TransferService.WRITE_UUID && characteristic.properties.contains(.write)) {
                                print("Writing data of \(peripherals[index].identifier.uuidString) with response...")
                                peripherals[index].writeValue(Data([0x17]), for: characteristic, type: CBCharacteristicWriteType.withResponse)
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
        if let uuid = self.pressedUUID?.uuidString {
            let arr = BLScanner.shared.getInformation(uuid: uuid)

            var alertStyle = UIAlertController.Style.actionSheet
            if (UIDevice.current.userInterfaceIdiom == .pad) {
                alertStyle = UIAlertController.Style.alert
            }

            let alert = UIAlertController(title: "Share Content", message: "Please Select an Option", preferredStyle: alertStyle)

            alert.addAction(UIAlertAction(title: "Original File", style: .default , handler:{ (UIAlertAction) in
                print("User click Original File button")

                for data in arr {
                    self.stringToBeShared += "\(data)\n"
                }
                let items = [self.stringToBeShared]
                self.stringToBeShared = ""
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    ac.popoverPresentationController?.sourceView = self.view
                    ac.popoverPresentationController?.sourceRect = CGRect(x: self.shareButton.center.x, y: self.shareButton.center.y,width: 0,height: 0)
                }
                self.present(ac, animated: true)
            }))

            alert.addAction(UIAlertAction(title: "Unprocessed File", style: .default , handler:{ (UIAlertAction) in
                print("User click Unprocessed File button")

                for data in arr where !(data.starts(with: String(decoding: [0x08], as: UTF8.self))) {
                    self.stringToBeShared += "\(data)\n"
                }

                let items = [self.stringToBeShared]
                self.stringToBeShared = ""
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    ac.popoverPresentationController?.sourceView = self.view
                    ac.popoverPresentationController?.sourceRect = CGRect(x: self.shareButton.center.x, y: self.shareButton.center.y,width: 0,height: 0)
                }
                self.present(ac, animated: true)
            }))

            alert.addAction(UIAlertAction(title: "Processed File", style: .default , handler:{ (UIAlertAction) in
                print("User click Processed File button")

                for data in arr where data.starts(with: String(decoding: [0x08], as: UTF8.self)) {
                    self.stringToBeShared += "\(data)\n"
                }
                let items = [self.stringToBeShared]
                self.stringToBeShared = ""
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    ac.popoverPresentationController?.sourceView = self.view
                    ac.popoverPresentationController?.sourceRect = CGRect(x: self.shareButton.center.x, y: self.shareButton.center.y,width: 0,height: 0)
                }
                self.present(ac, animated: true)
            }))

            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction) in
                print("User click Dismiss button")
            }))

            self.present(alert, animated: true, completion: {
                print("Completion block")
            })
        }
    }

    /// Plots the data when pressed
    /// - Parameter sender: Any touch on button
    @IBAction func plotButtonPressed(_ sender: Any) {
        if let uuid = pressedUUID?.uuidString {
            let arr = BLScanner.shared.getInformation(uuid: uuid)
            var arrData: [String] = []

            for data in arr where !(data.starts(with: String(decoding: [0x08], as: UTF8.self))) {
                arrData.append(data)
            }

            let (sensorDataMultipleMeasurements,_) = decodeData(rawData: arrData)
            UserDefaults.standard.setValue(sensorDataMultipleMeasurements, forKey: "dataArray")

            let vc: PlotMeasurementsViewController = self.storyboard?.instantiateViewController(withIdentifier: "PlotMeasurementsViewController") as! PlotMeasurementsViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    /// Tells the data source to return the number of rows in a given section of a table view.
    /// - Parameters:
    ///   - tableView: The table-view object requesting this information.
    ///   - section: An index number identifying a section in tableView.
    /// - Returns: The number of rows in section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  BLScanner.shared.getConnectedObjects().count
    }

    /// Asks the data source for a cell to insert in a particular location of the table view.
    /// - Parameters:
    ///   - tableView: A table-view object requesting the cell.
    ///   - indexPath: An index path locating a row in tableView.
    /// - Returns: An object inheriting from UITableViewCell that the table view can use for the specified row. UIKit raises an assertion if you return nil.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customTableViewCell", for: indexPath) as! CustomTableViewCell

        let currentKey = BLScanner.shared.getConnectedObjectsKeys()[indexPath.row]
        if let peripheral : CBPeripheral = BLScanner.shared.getConnectedObjects()[currentKey] {
            cell.peripheralName.text = "Name: \(peripheral.name ?? "Name Unknown")"
            cell.peripheralName.adjustsFontSizeToFitWidth = true
            cell.peripheralName.minimumScaleFactor = 0.25
        }

        let retrievalKey = BLScanner.shared.getRetrievalStatusKeys()[indexPath.row]
        if let retrievalValue : MutableProperty<Bool> = BLScanner.shared.getRetrievalStatus()[retrievalKey] {
            cell.dealWithLoadingSpinner(retrievalValue: retrievalValue.value)
        }

        return cell
    }

    /// Tells the delegate a row is selected.
    /// - Parameters:
    ///   - tableView: A table view informing the delegate about the new row selection.
    ///   - indexPath: An index path locating the new selected row in tableView.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentKey = BLScanner.shared.getConnectedObjectsKeys()[indexPath.row]
        let retrievalKey = BLScanner.shared.getRetrievalStatusKeys()[indexPath.row]
        if let peripheral : CBPeripheral = BLScanner.shared.getConnectedObjects()[currentKey] {
            if let retrievalValue : MutableProperty<Bool> = BLScanner.shared.getRetrievalStatus()[retrievalKey] {
                if retrievalValue.value == false && BLScanner.shared.getAllInformation().keys.contains(peripheral.identifier.uuidString) {
                    self.title = "Selected Device: \(BLScanner.shared.getConnectedObjects()[peripheral.identifier.uuidString]?.name ?? "Name Unknown")"
                    pressedUUID = peripheral.identifier
                    isPressedUUIDNil.value = false
                } else if retrievalValue.value == false && !BLScanner.shared.getAllInformation().keys.contains(peripheral.identifier.uuidString) {
                    self.title = "Selected device has not retrieved data yet"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        self.title = "Connected Device(s)"
                    })
                } else {
                    self.title = "Selected device is still retrieving data..."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        self.title = "Connected Device(s)"
                    })
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    /// Configures the table view
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150.0
    }

    func didFindObject(object: CBPeripheral) -> Bool {
        if BLScanner.shared.getConnectedObjects().values.contains(object) {
            return true
        } else {
            return false
        }
    }

    func didDisappear(object: CBPeripheral) -> Bool {
        if !BLScanner.shared.getConnectedObjects().values.contains(object) {
            return true
        } else {
            return false
        }
    }

    func update(_ sender: BLScanner) {
        self.tableView.reloadData()
    }

    func didFindInfo(_ value: String) {
        self.showAlert("BL manufacturer info ", body: value)
    }

    func showAlert (_ title: String, body: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Info Alert", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}
