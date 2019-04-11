//
//  ViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import UIKit

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
        scanner.displayObjects()
        
        configureTableView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return scanner.getVisibleObjects().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        
        cell.textLabel?.text = "Name: \(scanner.getVisibleObjects()[indexPath.row].displayName ?? "Name Unknown")       RSSI: \(scanner.getVisibleObjects()[indexPath.row].RSSI ?? "RSSI Unknown")"
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.25
        return cell
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
        self.configureTableView()
        self.tableView.reloadData()
    }
}

