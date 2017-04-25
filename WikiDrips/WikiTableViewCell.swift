//
//  WikiTableViewCell.swift
//  WikiDrips
//
//  Created by Bart Cullimore on 4/1/17.
//  Copyright © 2017 Bart Cullimore. All rights reserved.
//

import UIKit

class WikiTableViewCell: UITableViewCell {

    @IBOutlet weak var wikiTitleImageView: UIImageView?
    @IBOutlet weak var wikiTitleLabel: UILabel?
    @IBOutlet weak var wikiDateLabel: UILabel?
    public var wikiDoc: WikiDoc?
}
