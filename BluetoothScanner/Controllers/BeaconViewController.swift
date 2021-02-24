//
//  BeaconViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 24/02/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import UIKit
import CoreBluetooth

class BeaconViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var servicesTableView: UITableView!
    @IBOutlet weak var characteristicsTableView: UITableView!

    var servicesArray:  [CBService]?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        servicesTableView.delegate = self
        servicesTableView.dataSource = self
        servicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "servicesCustomCell")
        servicesTableView.rowHeight = UITableView.automaticDimension

        characteristicsTableView.delegate = self
        characteristicsTableView.dataSource = self
        characteristicsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "characteristicsCustomCell")
        characteristicsTableView.rowHeight = UITableView.automaticDimension

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

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func shareButtonPressed(_ sender: Any) {

    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
            case servicesTableView:
                return servicesArray?.count ?? 0
            case  characteristicsTableView:
                var count  = 0
                if let services = servicesArray {
                    for service in services {
                        if let characteristics = service.characteristics {
                            for _ in characteristics {
                                count += 1
                            }
                        }
                    }
                }
                return count
            default:
                fatalError("Invalid table")
            }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    }
}
