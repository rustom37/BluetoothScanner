//
//  CustomTableViewCell.swift
//  Swimtraxx Data Tool
//
//  Created by Steve Rustom on 26/07/2021.
//  Copyright © 2021 Capetech. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!

    lazy var isLoading = Property(_isLoading)
    private let _isLoading: MutableProperty<Bool> = MutableProperty(false)

    // Initialization code
    override func awakeFromNib() { super.awakeFromNib() }

    // Configure the view for the selected state
    override func setSelected(_ selected: Bool, animated: Bool) { super.setSelected(selected, animated: animated) }
}

extension Reactive where Base: CustomTableViewCell {
    var isLoading: BindingTarget<Bool> {
        makeBindingTarget { (cell, isLoading) in
            isLoading ? cell.loadingSpinner.startAnimating() : cell.loadingSpinner.stopAnimating()
        }
    }
}