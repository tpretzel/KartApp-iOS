//
//  SettingsTVC.swift
//  karteikarten
//
//  Created by D. Vogt on 23.07.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import UIKit
import CoreData

class SettingsTVC: UITableViewController, UITextFieldDelegate {
    
    var titelString: String! = "Einstellungen"
    
    @IBOutlet weak var switchExam: UISwitch!
    @IBOutlet weak var switchAutoSync: UISwitch!
    @IBOutlet weak var copyrightLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switchExam.setOn(examMode!, animated: true)
        switchAutoSync.setOn(autoSync!, animated: true)
        
        // NavigationBar Titel anpassen
        let titelNavBar: UILabel = UILabel(frame: CGRectMake(0,0,100,32))
        titelNavBar.text = self.titelString
        self.navigationItem.titleView = titelNavBar
        
        copyrightLabel.text = " © 2015 KartApp-Team[HS-Osnabrück] - KartApp \(kVersion)"
        
    }
    
    // Logout Button: Löscht alle lokalen Daten und zeigt das Login
    @IBAction func LogoutTapped(sender: AnyObject) {
        DLog("COreData: Alle lokalen User löschen")
        User.deleteAllLocalUser()
        
        DLog("CoreData: Lösche alle lokalen Karrtensätze")
        Cardsets.deleteAllLocalCardsets()
        
        DLog("CoreData: Lösche alle lokalen Karten")
        Cards.deleteAllLocalCards()
        
        DLog("UI: Zeige LoginView")
        self.performSegueWithIdentifier("showLogin", sender: self)
    }
    
    // Löscht alle lokalen Kartensätze und Karten
    @IBAction func cleanCache(sender: AnyObject) {
        Cards.deleteAllLocalCards()
        Cardsets.deleteAllLocalCardsets()

        Meldung("Hinweis", message: "Lokale Datenbank wurde komplett geleert!", btnTitle: "OK")
    }
    
    // Öffnet das Impressum
    @IBAction func impressumTapped(sender: AnyObject) {
        let url = "http://karta.dima23.de/impressum.php"
        DLog("Web: Öffne \(url)")
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }
    
    // Öffnet den Datenschutz-Hinweis
    @IBAction func datenschutzTapped(sender: AnyObject) {
        let url = "http://karta.dima23.de/privacy.php"
        DLog("Web: Öffne \(url)")
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }

    // Prüfungsmodus in die lokale DB schreiben
    @IBAction func switchChanged(sender: AnyObject) {
        DLog("Config: Setze exemMode auf \(switchExam.on)")
        examMode = switchExam.on
        
        // Wert in die lokal DB schreiben
        let fReq: NSFetchRequest = NSFetchRequest(entityName: "User")
        let userid: String! = cuser["userid"]
        fReq.predicate = NSPredicate(format: "userid == %@", userid)
        let sorter: NSSortDescriptor = NSSortDescriptor(key: "username" , ascending: false)
        fReq.sortDescriptors = [sorter]
        fReq.returnsObjectsAsFaults = false
        
        var result: [AnyObject]?
        do {
            result = try CoreData.sharedInstance.managedObjectContext!.executeFetchRequest(fReq)
        } catch {

        }
        for resultItem in result! {
            let user = resultItem as! User
            //println(user)
            user.examMode = examMode!
        }
        CoreData.sharedInstance.saveContext()
    }
    
    // AutoSync Option in die lokale DB schreiben
    @IBAction func switchAutoSync(sender: UISwitch) {
        DLog("Config: Setze autoSync auf \(switchAutoSync.on)")
        autoSync = switchAutoSync.on
        
        // Wert in die lokal DB schreiben

        let fReq: NSFetchRequest = NSFetchRequest(entityName: "User")
        let userid: String! = cuser["userid"]
        fReq.predicate = NSPredicate(format: "userid == %@", userid)
        let sorter: NSSortDescriptor = NSSortDescriptor(key: "username" , ascending: false)
        fReq.sortDescriptors = [sorter]
        fReq.returnsObjectsAsFaults = false
        
        var result: [AnyObject]?
        do {
            result = try CoreData.sharedInstance.managedObjectContext!.executeFetchRequest(fReq)
        } catch{

        }
        for resultItem in result! {
            let user = resultItem as! User
            //println(user)
            user.autoSync = autoSync!
        }
        CoreData.sharedInstance.saveContext()
    }

    // Neue E-Mail mit vorgegebenen Daten öffnen
    @IBAction func feedbackTapped(sender: AnyObject) {
        let url = "mailto:kartaapp@outlook.de?subject=KartApp-Feedback"
        DLog("Web: Öffne \(url)")
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }
}
