//
//  CustomTableViewCell.swift
//  Swimtraxx Data Tool
//
//  Created by Steve Rustom on 26/07/2021.
//  Copyright © 2021 Capetech. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var completedPercentage: UILabel!
    @IBOutlet weak var emptyFlashIcon: UIImageView!

    /// Initialization code
    override func awakeFromNib() { super.awakeFromNib() }

    /// Configure the view for the selected state
    override func setSelected(_ selected: Bool, animated: Bool) { super.setSelected(selected, animated: animated)
    }

    /// Functions to hide the content of the image view or not
    func dealWithImageView(flashEmpty: Bool) {
        if flashEmpty {
            emptyFlashIcon.isHidden = false
        } else {
            emptyFlashIcon.isHidden = true
        }
    }
}
