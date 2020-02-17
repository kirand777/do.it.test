//
//  TaskTableViewCell.swift
//  DOITTestApp
//
//  Created by Kirill Andreyev on 2/16/20.
//  Copyright © 2020 Kirill Andreyev. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var priorityLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
