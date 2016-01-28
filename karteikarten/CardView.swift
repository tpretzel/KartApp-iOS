//
//  CardView.swift
//  
//
//  Created by D. Vogt on 10.09.15.
//
//

import Foundation
import UIKit

class CardView: UIViewController {
    
    @IBOutlet weak var frageText: UITextView!
    @IBOutlet weak var antwortText: UITextView!

    var frage: String = ""
    var antwort: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frageText.textAlignment = NSTextAlignment.Center
        frageText.text = frage
        
        antwortText.textAlignment = NSTextAlignment.Center
        antwortText.text = antwort
        
    }
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: {})
    }    
}
