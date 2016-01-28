//
//  CardsetCell.swift
//  karteikarten
//
//  Created by D. Vogt on 20.05.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import UIKit

class CardsetCell: UITableViewCell {


    @IBOutlet weak var cardsetName: UILabel!
    @IBOutlet weak var cardsetSubtitle: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var permission: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //progressBar.transform = CGAffineTransformScale(progressBar.transform, 1, 2)
    }
    
    

}
