//
//  ShareVC.swift
//
//  ShareViewController
//  Controller für die Freigabe-Funktionen der Kartensätze
//  Anzeigen, Hinzufügen und Löschen von Berechtigungen eines Kartensatzes
//

import UIKit
import Alamofire
import SwiftyJSON

class ShareVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var exitCardset: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var titelString: String? = nil
    var refreshCtrl: UIRefreshControl!
    let basicCell = "BasicCell"
    // eigene Permission für den gewählten Kartensatz
    var myPermission: String? = nil
    // Dictionary die alle Freigaben zwischenspeichert
    var permissions: [(userid: String, username: String, permission: String)] = []
    // Anzahl Besitzer eines Kartensatzes
    var countOwner: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NavigationBar anpassen
        let titelNavBar: UILabel = UILabel(frame: CGRectMake(0,0,100,32))
        titelNavBar.textAlignment = .Center
        titelNavBar.text = self.titelString
        self.navigationItem.titleView = titelNavBar
        // + Button der Navigation hinzufügen
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addFriendAction")
        
        // Leere Zellen in der Tabelle ausblenden
        self.tableView.tableFooterView = UIView()
        
        // Prüfen ob eine Internetverbindung besteht
        // Bei Erfolg: Berechtigungen laden
        // Bei Fehler: Text in dem Fehler-Label anzeigen
        if Reachability.isConnectedToNetwork() == true {
            self.errorLabel.text = ""
            loadFriends(Int(setid!)!)
        }else{
            self.errorLabel.text = "Es besteht momentan keine Verbindung zum Internet. Bitte versuchen Sie es später erneut."
        }
        
        // Pull Methode (runterziehen zum aktualisieren) der Tabelle hinzufügen
        self.refreshCtrl = UIRefreshControl()
        self.refreshCtrl.attributedTitle = NSAttributedString(string: "Berechtigungen werden aktualisiert")
        self.refreshCtrl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshCtrl)
        
        // Tabellen Methoden an den Controller delegieren
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        
    }
    
    // MARK: RefreshControl
    // Pull Methode (runterziehen zum aktualisieren)
    func refresh(sender:AnyObject){
        if Reachability.isConnectedToNetwork() == true {
            loadFriends(Int(setid!)!)
            self.errorLabel.text = ""
        }else{
            self.refreshCtrl.endRefreshing()
            self.errorLabel.text = "Es besteht momentan keine Verbindung zum Internet. Bitte versuchen Sie es später erneut."
            MeldungKeinInternet()
        }
    }
    
    // MARK: Tabellen Funktionen
    // Anzahl der Zellen zurückgeben
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return permissions.count
    }
    
    // Zellen Eigenschaften Definition
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(basicCell)!
        
        // Berechtigung nach Besitzer sortieren
        permissions.sortInPlace({$0.permission < $1.permission})
        
        if permissions[indexPath.row].permission == "0" {
            
            countOwner++
            
            if permissions[indexPath.row].userid == cuser["userid"] {
                cell.detailTextLabel?.text = "📌👤 Besitzer"
                cell.userInteractionEnabled = false
                if countOwner == 1 {
                    exitCardset.enabled = false
                    exitCardset.backgroundColor = UIColor.grayColor()
                }
            }else{
                cell.detailTextLabel?.text = "👤 Besitzer"
                cell.userInteractionEnabled = true
                exitCardset.enabled = true
                exitCardset.backgroundColor = kBlue
            }
            cell.textLabel?.text = permissions[indexPath.row].username
        }else{
            cell.textLabel?.text = permissions[indexPath.row].username
            if permissions[indexPath.row].userid == cuser["userid"] {
                cell.detailTextLabel?.text = "📌👥 Teilnehmer"
                cell.userInteractionEnabled = false
            }else{
                cell.detailTextLabel?.text = "👥 Teilnehmer"
                cell.userInteractionEnabled = true
            }
        }
        
        if self.myPermission == "1" {cell.userInteractionEnabled = false}
        
        return cell
    }
    
    // Löschen-Funktion der Zelle hinzufügen
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "löschen") { (action, indexPath) -> Void in
            tableView.editing = false
            if Reachability.isConnectedToNetwork() == true {
                self.deleteFriend(self.permissions[indexPath.row].username)
                self.permissions.removeAtIndex(indexPath.row)
                self.countOwner = 0
                self.tableView.reloadData()
            }else{
                
            }
        }
        
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [deleteAction]
    }
    
    // MARK: ???
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    // Kartensatz verlassen Funktion
    // Kartensatz verlassen und in die Kartensatzansicht wechseln
    @IBAction func leaveButtonTapped(sender: AnyObject) {
        
        let alert = UIAlertController(title: "Kartensatz verlassen", message: "Wollen Sie wirklich den Kartensatz verlassen?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ja", style: .Default, handler:{ (UIAlertAction)in
            if Reachability.isConnectedToNetwork() == true {
                self.leaveCardset()
            }else{
                MeldungKeinInternet()
            }
        }))
        alert.addAction(UIAlertAction(title: "Nein", style: .Cancel) { (_) in })
        
        self.presentViewController(alert, animated: true, completion: { })
    }
    
    // Berechtigung für Kartensatz laden
    // Tabelle neuladen und RefreshControl-Animation beenden
    func loadFriends(setid: Int){
        DLog("HTTP POST: Karten werden geladen")
        Session.sharedInstance.ApiManager().request(.GET, apiURL+"/permission?cardsetid=\(setid)")
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Berechtigungen erfolgreich geladen")
                    self.permissions.removeAll(keepCapacity: false)
                    for index in 0 ..< json["permissions"].count {
                        let id: String? = json["permissions"][index]["userid"].stringValue
                        let username: String? = json["permissions"][index]["username"].stringValue
                        let permission: String? = json["permissions"][index]["permission"].stringValue
                        self.permissions += [(userid: id!, username: username!, permission: permission!)]
                        if id == cuser["userid"] {self.myPermission = permission}
                    }
                    self.tableView.reloadData()
                }else{
                    DLog("HTTP POST Response: Berechtigung konnte nicht geladen werden")
                    //DLog(error!.localizedDescription)
                }
                self.refreshCtrl.endRefreshing()
            })
    }
    
    // Berechtugung für Kartensatz löschen
    func deleteFriend(username: String){
        Session.sharedInstance.ApiManager().request(.DELETE, apiURL+"/permission/\(setid!)?username=\(username)")
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Benutzer wurde gelöscht")
                    if json["error"] == true {
                        Meldung("Fehler", message: json["message"].stringValue, btnTitle: "OK")
                    }
                    
                }else{
                    DLog("HTTP POST Response: Benutzer konnten nicht gelöscht werden")
                    //DLog(error!.localizedDescription)
                }
                self.refreshCtrl.endRefreshing()
            })
    }
    
    // Kartensatz verlassen
    func leaveCardset(){
        Session.sharedInstance.ApiManager().request(.DELETE, apiURL+"/permission/\(setid!)?username=" + cuser["username"]!)
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Benutzer wurde gelöscht")
                    if json["error"] == true {
                        Meldung("Fehler", message: json["message"].stringValue, btnTitle: "OK")
                    }
                    
                    self.performSegueWithIdentifier("showCardsetView", sender: self)
                    
                }else{
                    DLog("HTTP POST Response: Benutzer konnten nicht gelöscht werden")
                    //DLog(error!.localizedDescription)
                }
                self.refreshCtrl.endRefreshing()
            })
    }
    
    // Hinzufügen Funktion
    func addFriendAction(){
        if self.myPermission == "0" {
            let alert = UIAlertController(title: "Freigabe", message: "Geben Sie den Benutzernamen ein:", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addTextFieldWithConfigurationHandler({(textField: UITextField) in
                textField.placeholder = "Benutzername"
                textField.secureTextEntry = false
            })
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .Cancel) { (_) in })
            alert.addAction(UIAlertAction(title: "👥 Teilnehmer", style: .Default, handler:{ (UIAlertAction)in
                let name = alert.textFields![0] 
                if Reachability.isConnectedToNetwork() == true {
                    self.addPermission(name.text!, permission: "1")
                }else{
                    
                }
            }))
            alert.addAction(UIAlertAction(title: "👤 Besitzer", style: .Default, handler:{ (UIAlertAction)in
                let name = alert.textFields![0] 
                if Reachability.isConnectedToNetwork() == true {
                    self.addPermission(name.text!, permission: "0")
                }else{
                    
                }
            }))
            self.presentViewController(alert, animated: true, completion: { })
        }else{
            Meldung("Fehler", message: "Sie haben keine Berechtigung!", btnTitle: "OK")
        }
    }
    
    // Berechtigung online hinzufügen
    func addPermission(username: String, permission: String){
        Session.sharedInstance.ApiManager().request(.POST, apiURL+"/permission/\(setid!)", parameters: ["username":username, "permission":permission])
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Benutzer wurde erfolgreich hinzugefügt")
                    
                    if json["error"] == true {
                        Meldung("Fehler", message: json["message"].stringValue, btnTitle: "OK")
                    }else{
                        self.permissions += [(userid: "", username: username, permission: permission)]
                        self.tableView.reloadData()
                    }
                    
                }else{
                    DLog("HTTP POST Response: Benutzer konnten nicht hinzugefügt werden")
                    //DLog(error!.localizedDescription)
                }
                self.refreshCtrl.endRefreshing()
            })
    }
    
}
