//
//  User.swift
//  
//
//  Created by D. Vogt on 29.09.15.
//
//

import Foundation
import CoreData
import SwiftyJSON
import Alamofire

protocol UserProtocol {
    func didUserLogin(results: JSON)
    func didUserRegister(results: JSON)
    func didUserResetPassword(results: JSON)
}

@objc(User)
class User: NSManagedObject {

    @NSManaged var apikey: String
    @NSManaged var autoSync: NSNumber
    @NSManaged var cardsToLearn: NSNumber
    @NSManaged var email: String
    @NSManaged var examMode: NSNumber
    @NSManaged var loggedIn: NSNumber
    @NSManaged var timestamp: NSDate
    @NSManaged var userid: NSNumber
    @NSManaged var username: String
    @NSManaged var cardsets: NSSet

    var delegate: UserProtocol?
    
    // Schreibt die Userdaten in die lokale Datenbank
    static func createLocalUser (apikey: String, email: String, userid: NSNumber, username: String) -> User {
        let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!) as! User
        
        user.apikey = apikey
        user.email = email
        user.userid = userid
        user.username = username
        user.examMode = false
        user.autoSync = true
        user.loggedIn = true
        user.timestamp = NSDate()
        user.cardsToLearn = 30
        
        // println(user)
        CoreData.sharedInstance.saveContext()
        DLog("CoreData: Benutzer wurde gespeichert")
        
        return user
    }
    
    // löscht ein Objekt aus der lokalen Datenbank
    func delete() {
        CoreData.sharedInstance.managedObjectContext?.deleteObject(self)
        CoreData.sharedInstance.saveContext()
    }
    
    // fragt alle lokalen Userobjekte ab und löscht sie mit delete()
    static func deleteAllLocalUser() {
        let request = NSFetchRequest(entityName: "User")
        if let allUsers = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [User] {
            for user in allUsers {
                user.delete()
            }
        }
    }
    
    // logt einen Benutzer ein
    func login(username:String, password:String){
        DLog("HTTP POST: Login wird ausgeführt")
        Alamofire.request(.POST, apiURL+"/login", parameters: ["username":username, "password": password])
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Login ausgeführt")
                    self.delegate?.didUserLogin(json)
                }else{
                    DLog("HTTP POST Response: Login konnte nicht durchgeführt werden")
                    //DLog(error!.localizedDescription)
                }
            })
    }
    
    // registriert einen neuen Benutzer
    func register(email: String, username: String, password:String){
        DLog("HTTP POST: Registrierung wird ausgeführt")
        Alamofire.request(.POST, apiURL+"/register", parameters: ["username":username, "password": password, "email": email])
            .responseSwiftyJSON({ (request, response, json, error) in
                if (error == nil){
                    DLog("HTTP POST Response: Registrierung erfolgreich")
                    self.delegate?.didUserRegister(json)
                }else{
                    DLog("HTTP POST Response: Registrierung konnte nicht durchgeführt werden")
                    DLog("\(error)")
                }
            })
    }
    
    // setzt das Passwort zurück
    func resetpassword(email:String) -> Bool {
        DLog("HTTP POST: Reset Passwort")
        Alamofire.request(.POST, apiURL+"/resetpw", parameters: ["email": email])
            .responseSwiftyJSON({ (request, response, json, error) in
                if (error == nil){
                    DLog("HTTP POST Response: Passwort zurückgesetzt")
                    self.delegate?.didUserResetPassword(json)
                }else{
                    DLog("HTTP POST Response: Passwort nicht zurückgesetzt")
                    DLog("\(error)")
                }
            })
        return true
    }
    
    // Setzt den examMode Wert in der DB
    func setExamTo(value: Bool){
        self.examMode = value
        CoreData.sharedInstance.saveContext()
    }
    
    // Setzt den autoSync Wert in der DB
    func setAutoSyncTo(value: Bool){
        self.autoSync = value
        CoreData.sharedInstance.saveContext()
    }

}
