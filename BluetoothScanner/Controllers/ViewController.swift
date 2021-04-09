//
//  ViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BLScannerDelegate {

    @IBOutlet weak var tableView: UITableView!
    let scanner = BLScanner()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        scanner.startScan()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        
        scanner.delegate = self
        configureTableView()
        scanner.displayObjects()
    
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return scanner.getVisibleObjects().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        
        cell.textLabel?.text = "Name: \(scanner.getVisibleObjects()[indexPath.row].displayName ?? "Name Unknown")"
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.25
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let  peripheral = scanner.getVisibleObjects()[indexPath.row].peripheral {
            scanner.centralManager?.connect(peripheral, options: nil)
            self.title = "Connected to \(scanner.getVisibleObjects()[indexPath.row].displayName ?? "Uknown Device")"
            tableView.deselectRow(at: indexPath, animated: true)

            let vc: BeaconViewController = self.storyboard?.instantiateViewController(withIdentifier: "BeaconViewController") as! BeaconViewController
            vc.peripheral = peripheral
            vc.availableScanner = scanner
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150.0
    }
    
    func didFindObject(object: BLObject) -> Bool {
        if scanner.getVisibleObjects().contains(object) {
            return true
        } else {
            return false
        }
    }
    
    func didDisappear(object: BLObject) -> Bool {
        if !scanner.getVisibleObjects().contains(object) {
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
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

