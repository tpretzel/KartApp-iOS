//
//  LoginVC.swift
//  karteikarten
//
//  Created by D. Vogt on 27.05.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON

class LoginVC: UIViewController, NSFetchedResultsControllerDelegate, UserProtocol, UITextFieldDelegate {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnHinweis: UIButton!

    @IBOutlet weak var btnPasswortVergessen: UIButton!
    @IBOutlet weak var btnKontoErstellen: UIButton!
    @IBOutlet weak var btnAnmelden: UIButton!
    @IBOutlet weak var btnPasswortZuruecksetzen: UIButton!
    @IBOutlet weak var txtBenutzername: UITextField!
    @IBOutlet weak var txtPasswortErstellen: UITextField!

    @IBOutlet weak var switchAnmelden: UIButton!
    @IBOutlet weak var switchKontoErstellen: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        //User.deleteAllLocalUser()
        DLog("App wird gestartet")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        // Bei zurückkehren (Logout) zum LoginVC die Navigation ausblenden
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        // Wenn Benutzer bereits eingeloggt ist, die Kartensätze anzeigen
        if isLoggedIn() {
            DLog("User ist bereits eingeloggt!")
            self.performSegueWithIdentifier("showCardsets", sender: self)
        }
    }
    
    // Tastatur ausblenden
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //self.view.endEditing(true)
        textField.resignFirstResponder()
        return false
    }

    // MARK: Zustände: Anmelden/Konto erstellen/Registrieren
    // Blendet bestimmte TextFelder/Buttons ein/aus
    
    @IBAction func switchAnmelden(sender: AnyObject) {
        DLog("Zustand: Anmelden")
        btnKontoErstellen.hidden = true
        switchAnmelden.hidden = true
        btnPasswortZuruecksetzen.hidden = true
        txtEmail.placeholder = "Benutzername";
        txtBenutzername.hidden = true
        txtPasswortErstellen.hidden = true
        btnHinweis.hidden = true

        switchKontoErstellen.hidden = false
        btnPasswortVergessen.hidden = false
        btnAnmelden.hidden = false
        txtPassword.hidden = false
    }

    @IBAction func switchKontoErstellen(sender: AnyObject) {
        DLog("Zustand: Konto erstellen")
        btnAnmelden.hidden = true
        btnPasswortVergessen.hidden = true
        txtPassword.hidden = true
        switchKontoErstellen.hidden = true

        btnKontoErstellen.hidden = false
        txtBenutzername.hidden = false
        txtPasswortErstellen.hidden = false
        switchAnmelden.hidden = false
        btnHinweis.hidden = false
        txtEmail.placeholder = "E-Mail Adresse";

        btnHinweis.setTitle("Durch Klicken auf \"Konto erstellen\" aktzeptiere ich die Nutzungsbedingungen und die Datenschutzrichtlinie.", forState: UIControlState.Normal)
        btnHinweis.titleLabel?.textAlignment = .Center
        btnHinweis.titleLabel?.lineBreakMode = .ByWordWrapping
        btnHinweis.titleLabel?.numberOfLines = 2
        btnHinweis.titleLabel?.adjustsFontSizeToFitWidth = true
    }


    @IBAction func PasswortVergessenButtonTapped(sender: AnyObject) {
        DLog("Zustand: Passwort vergessen")
        btnAnmelden.hidden = true
        btnKontoErstellen.hidden = true
        switchKontoErstellen.hidden = true
        btnPasswortVergessen.hidden = true
        txtPassword.hidden = true
        txtEmail.placeholder = "E-Mail-Adresse";
        txtBenutzername.hidden = true
        txtPasswortErstellen.hidden = true
        btnHinweis.hidden = true

        switchAnmelden.hidden = false
        btnPasswortZuruecksetzen.hidden = false
    }

    @IBAction func AnmeldenButtonTapped(sender: AnyObject) {
        // LOGIN Funktion
        if(txtEmail.text!.isEmpty || txtPassword.text!.isEmpty){
            Meldung("Fehler", message: "Bitte beide Felder ausfüllen!", btnTitle: "Fehler")
        }else{

          // Verbindung zum Internet prüfen vor Login
          if Reachability.isConnectedToNetwork() == true {
            DLog("Internetverbindung vorhanden")
            let username = txtEmail.text
            let password = txtPassword.text

            let entityDescription = NSEntityDescription.entityForName("User",inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!)
            let user = User(entity: entityDescription!, insertIntoManagedObjectContext: CoreData.sharedInstance.managedObjectContext)

            user.delegate = self

            // Spinner anzeigen
            let spinner = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            spinner.labelText = "Anmelden"
            spinner.detailsLabelText = "Bitte warten..."
            spinner.dimBackground = true
            
            DLog("Starte LOGIN-Prozess")
            user.login(username!, password: password!)
          }

        else {
            DLog("KEINE Internetverbindung vorhanden")
            Meldung("keine Internetverbindung", message: "Bitte stellen Sie eine Verbindung mit dem Internet her", btnTitle: "OK")
        }
      }
    }

    // Bei erolgreicher Verbindung zur Online-DB
    // und ausführen der Login-Funktion
    func didUserLogin(results: JSON){
        dispatch_async(dispatch_get_main_queue(), {
            if(results["error"]){
                DLog("HTTP POST Response: Benutzer konnte nicht angemeldet werden")
                let alertView = UIAlertView();
                alertView.addButtonWithTitle("OK")
                alertView.title = "Fehler"
                alertView.message = "Sie konnten nicht angemeldet werden!"
                alertView.show()
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            }else{
                DLog("HTTP POST Response: Benutzer konnte angemeldet werden")
                let userid = results["userid"]
                let username = results["username"]
                let email = results["email"]
                
                // Daten in Variablen zwischenspeichern
                capikey = results["apikey"].stringValue
                cuser["userid"] = userid.stringValue
                cuser["username"] = username.stringValue
                cuser["email"] = email.stringValue
                cuser["apikey"] = capikey

                DLog("Benutzeranmeldung: [\(userid)]\(username)-\(email)-\(capikey)")

                
                DLog("CoreData: Benutzer wird gespeichert")
                User.createLocalUser(cuser["apikey"]!, email: cuser["email"]!, userid: Int(cuser["userid"]!)!, username: cuser["username"]!)
                
                examMode = false
                autoSync = true

                DLog("CoreData: Lösche alle lokalen Kartensätze")
                Cardsets.deleteAllLocalCardsets()
                
                DLog("UI: Zeige Katzensätze")
                self.performSegueWithIdentifier("showCardsets", sender: self)


            }
        })
    }

    // Registrieren Button
    @IBAction func KontoErstellenButtonTapped(sender: AnyObject) {
        if(txtEmail.text!.isEmpty || txtPasswortErstellen.text!.isEmpty || txtBenutzername.text!.isEmpty){
            Meldung("Fehler", message: "Bitte beide Felder ausfüllen!", btnTitle: "Fehler")
        }else{

            let entityDescription = NSEntityDescription.entityForName("User",inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!)
            let user = User(entity: entityDescription!,insertIntoManagedObjectContext: CoreData.sharedInstance.managedObjectContext)

            user.delegate = self

            let spinner = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            spinner.labelText = "Registrierung"
            spinner.detailsLabelText = "Bitte warten..."
            spinner.dimBackground = true

            DLog("UserRegister wird ausgeführt")
            user.register(txtEmail.text!, username: txtBenutzername.text!, password:txtPasswortErstellen.text!)
        }
    }
    
    // Bei erolgreicher Verbindung zur Online-DB
    // und ausführen der Registrieren-Funktion
    func didUserRegister(results: JSON){
        dispatch_async(dispatch_get_main_queue(), {
            if(results["error"]){
                DLog("Benutzer konnte nicht registriert werden")
                let alertView = UIAlertView();
                alertView.addButtonWithTitle("OK")
                alertView.title = "Fehler"
                alertView.message = results["message"].stringValue
                alertView.show()
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            }else{
                DLog("Benutzer konnte erfolgreich registriert werden")
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                let alertView = UIAlertView();
                alertView.addButtonWithTitle("OK")
                alertView.title = "Erfolgreich registriert!"
                alertView.message = results["message"].stringValue
                alertView.show()
                self.txtEmail.text = ""
                self.txtPassword.text = ""
                self.switchAnmelden(self)

                DLog("Benutzer wurde ONLINE erstellt!")
            }
        })
    }

    // Passwort-Vergessen Funktion
    @IBAction func PasswortZuruecksetzenTapped(sender: AnyObject) {
        if(txtEmail.text!.isEmpty){
            Meldung("Fehler", message: "Bitte E-Mail-Adresse eingeben!", btnTitle: "OK")
        }else{
 
            let entityDescription = NSEntityDescription.entityForName("User",inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!)
            let user = User(entity: entityDescription!,insertIntoManagedObjectContext: CoreData.sharedInstance.managedObjectContext)

            user.delegate = self
            
            DLog("ResetPasswort wird ausgeführt")
            user.resetpassword(txtEmail.text!)
        }
    }

    // Bei erolgreicher Verbindung zur Online-DB
    // und ausführen der PasswortVergessen-Funktion
    func didUserResetPassword(results: JSON) {
        if(results["error"]){
            DLog("Passwort konnte nicht zurückgesetzt werden")
            let alertView = UIAlertView();
            alertView.addButtonWithTitle("OK")
            alertView.title = "Fehler"
            alertView.message = results["message"].stringValue
            alertView.show()
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        }else{
            DLog("Passwort zurückgesetzt")
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            let alertView = UIAlertView();
            alertView.addButtonWithTitle("OK")
            alertView.title = "Passwort zurückgesetzt!"
            alertView.message = results["message"].stringValue
            alertView.show()
            self.txtEmail.text = ""
            self.txtPassword.text = ""
            self.switchAnmelden(self)

            DLog("Passwort zurückgesetzt")
        }
    }

    // MARK: Verhalten der Textfelder beim Editieren/Verlassen
    
    @IBAction func emailEditingBegin(){
        txtEmail.placeholder = "";
    }

    @IBAction func passwordEditingBegin(){
        txtPassword.placeholder = "";
    }

    @IBAction func emailEditingEnd(){
        if(txtEmail.text == "" && switchKontoErstellen.hidden == true){
            txtEmail.placeholder = "E-Mail Adresse";
        }else if(txtEmail.text == "" && switchAnmelden.hidden == true){
            txtEmail.placeholder = "Benutzername";
        }
    }

    @IBAction func passwordEditingEnd(){
        if(txtPassword.text == ""){
            txtPassword.placeholder = "Passwort";
        }
    }

    @IBAction func BenutzernameEditingBegin(sender: AnyObject) {
        txtBenutzername.placeholder = ""
    }

    @IBAction func BenutzernameEditingEnd(sender: AnyObject) {
        if(txtBenutzername.text == ""){
            txtBenutzername.placeholder = "Benutzername"
        }
    }

    @IBAction func PasswortErstellenEditingBegin(sender: AnyObject) {
        txtPasswortErstellen.placeholder = ""
    }

    @IBAction func PasswortErstellenEditingEnd(sender: AnyObject) {
        if(txtPasswortErstellen.text == ""){
            txtPasswortErstellen.placeholder = "Passwort"
        }
    }

    // Datenschutz Hinweis anzeigen
    @IBAction func btnHinweisTapped(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://karta.dima23.de/privacy.php")!)
    }

    // Abfrage der lokalen DB, ob ein Benutzer bereits eingeloggt ist: isLoggedIn = true
    private func isLoggedIn () -> Bool{
        DLog("Prüfe ob Benutzer bereits eingeloggt ist")

        let fReq: NSFetchRequest = NSFetchRequest(entityName: "User")
        fReq.predicate = NSPredicate(format: "loggedIn == 1")
        let sorter: NSSortDescriptor = NSSortDescriptor(key: "username" , ascending: false)
        fReq.sortDescriptors = [sorter]
        fReq.returnsObjectsAsFaults = false

        var result: [AnyObject]?
        do{
            result = try CoreData.sharedInstance.managedObjectContext!.executeFetchRequest(fReq)
        }catch{
            
        }
        
        for resultItem in result! {
            let user = resultItem as! User
                //println(user)
                capikey = user.apikey
                cuser["username"] = user.username
                cuser["userid"] = user.userid.stringValue
                examMode = user.examMode as Bool
                autoSync = user.autoSync as Bool
                cardsToLearn = user.cardsToLearn
                
                let headers = ["Authorization": capikey!]
            
            
                var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
                defaultHeaders["DNT"] = "1 (Do Not Track Enabled)"
            
                let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
                configuration.HTTPAdditionalHeaders = headers
            
                let manager = Alamofire.Manager(configuration: configuration)
                //Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = headers

                return true
        }
        return false
    }
}
