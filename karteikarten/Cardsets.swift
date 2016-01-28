//
//  Cardsets.swift
//  
//
//  Created by D. Vogt on 23.09.15.
//
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

protocol CardsetsProtocol {
    func didCardsetsLoad(results: JSON)
}

@objc(Cardsets)
class Cardsets: NSManagedObject {

    @NSManaged var cardsetid: NSNumber
    @NSManaged var cardsetname: String
    @NSManaged var permission: NSNumber
    @NSManaged var syncdate: NSDate
    @NSManaged var cards: NSSet
    @NSManaged var user: User

    var delegate: CardsetsProtocol?
    
    // holt die Kartensätze aus der zentralen online-Datenbank
    func getAllCardsets(){
        
        let headers = ["Authorization": capikey!]
        
        Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = headers
        
        DLog("HTTP POST: Kartensätze werden geladen")
        
        Session.sharedInstance.ApiManager().request(.GET, apiURL+"/cardset")
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Kartensätze erfolgreich geladen")
                    self.delegate?.didCardsetsLoad(json)
                    
                }else{
                    DLog("HTTP POST Response: Kartensätze konnten nicht geladen werden")
                    //DLog(error!.localizedDescription)
                }
            })
    }
    
    // speichert Kartensätze in der lokalen Datenbank
    static func createLocalCardsets (cardsetid: NSNumber, cardsetname: String, permission: NSNumber) -> Cardsets {
        let cardsets = NSEntityDescription.insertNewObjectForEntityForName("Cardsets", inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!) as! Cardsets
        
        cardsets.cardsetid = cardsetid
        cardsets.cardsetname = cardsetname
        cardsets.permission = permission
        cardsets.syncdate = NSDate()
        
        
        return cardsets
    }
    
    // löscht ein Objekt aus der lokalen Datenbank
    func delete() {
        CoreData.sharedInstance.managedObjectContext?.deleteObject(self)
        CoreData.sharedInstance.saveContext()
    }
    
    // fragt alle lokalen Kartensatz-Objekte ab und löscht sie mit delete()
    static func deleteAllLocalCardsets() {
        let request = NSFetchRequest(entityName: "Cardsets")
        if let allCardsets = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [Cardsets] {
            for cardsets in allCardsets {
                cardsets.delete()
            }
        }
    }
}
