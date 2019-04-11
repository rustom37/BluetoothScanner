//
//  ViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 4/10/19.
//  Copyright © 2019 Steve Rustom. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    let scanner = BLScanner()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        scanner.startScan(tableView: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.configureTableView()
                self.tableView.reloadData()
            }
        }
        
        configureTableView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return scanner.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
        
        cell.textLabel?.text = "Name: \(scanner.peripherals[indexPath.row].displayName ?? "Name Unknown")       RSSI: \(scanner.peripherals[indexPath.row].RSSI ?? "RSSI Unknown")"
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.minimumScaleFactor = 0.25
        return cell
    }
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150.0
    }
}

