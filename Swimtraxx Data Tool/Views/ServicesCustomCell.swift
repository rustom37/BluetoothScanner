//
//  ServicesCustomCell.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 24/02/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import UIKit

class ServicesCustomCell: UITableViewCell {

    @IBOutlet weak var serviceUUID: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
