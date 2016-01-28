//
//  LearnViewController.swift
//  karteikarten
//
//  Created by D. Vogt on 19.05.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import UIKit

class LearnViewController: UIViewController {

    var titelString: String! = "test"
    var draggableBackground: DraggableViewBackground!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let titelNavBar: UILabel = UILabel(frame: CGRectMake(0,0,100,32))
        titelNavBar.text = self.titelString
        self.navigationItem.titleView = titelNavBar

        draggableBackground = DraggableViewBackground(frame: self.view.frame)
        self.view.addSubview(draggableBackground)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        draggableBackground.resetKnown()
    }

}
