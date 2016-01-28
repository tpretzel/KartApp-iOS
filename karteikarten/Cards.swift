//
//  Cards.swift
//  
//
//  Created by D. Vogt on 09.09.15.
//
//

import Foundation
import CoreData
import SwiftyJSON
import Alamofire

protocol CardsProtocol {
    func didCardsLoad(results: JSON)
}

@objc(Cards)
class Cards: NSManagedObject {

    @NSManaged var answer: String
    @NSManaged var cardid: NSNumber
    @NSManaged var cardsets_setid: NSNumber
    @NSManaged var question: String
    @NSManaged var type: NSNumber
    @NSManaged var box: NSNumber
    @NSManaged var cardset: Cardsets

    var delegate: CardsProtocol?    
    
    // läd die Daten aus der online-Datenbank
    func loadCards(cardsetid: Int!){
        
        DLog("HTTP POST: Karten werden geladen")
        Session.sharedInstance.ApiManager().request(.GET, apiURL+"/card", parameters: ["cardsetid":cardsetid])
            .responseSwiftyJSON({ (request, response, json, error) in
                //println(json)
                //println(error)
                
                if (error == nil){
                    DLog("HTTP POST Response: Karten erfolgreich geladen")
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        
                        self.delegate?.didCardsLoad(json)
                        
                    })
                }else{
                    DLog("HTTP POST Response: Karten konnten nicht geladen werden")
                    //DLog(error!.localizedDescription)
                }
            })
    }
    
    
    // löscht ein Objekt aus der lokalen Datenbank
    func delete() {
        CoreData.sharedInstance.managedObjectContext?.deleteObject(self)
        CoreData.sharedInstance.saveContext()
    }
    
    // fragt alle lokalen Karten ab und löscht sie mit delete()
    static func deleteAllLocalCards() {
        let request = NSFetchRequest(entityName: "Cards")
        if let allCards = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [Cards] {
            for cards in allCards {
                cards.delete()
            }
        }
    }
    
    // löscht alle lokalen Karten eines Kartensatzes
    static func deleteAllLocalCardsForCardset(setid: NSNumber) {
        let request = NSFetchRequest(entityName: "Cards")
        if let allCards = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [Cards] {
            for cards in allCards {
                if cards.cardsets_setid == setid {
                    cards.delete()
                }
            }
        }
    }
    
    // speichert eine Karte lokal ab
    static func createLocalCards(cardid: NSNumber, question: String, answer: String, cardsets_setid: NSNumber, type: NSNumber, box: NSNumber) -> Cards {
        let cards = NSEntityDescription.insertNewObjectForEntityForName("Cards", inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!) as! Cards
        
        cards.cardid = cardid
        cards.question = question
        cards.answer = answer
        cards.cardsets_setid = cardsets_setid
        cards.type = type
        cards.box = box
        //println(cards)
        DLog("Neue Karte wurde angelegt")
        //CoreData.sharedInstance.saveContext()
        
        return cards
    }
    
    // überschreibt lokale Karten mit NSBatchUpdateRequest falls Änderungen vorgenommen wurden
    // falls keine Karte gefunden wird, wird eine neue angelegt mit createLocalCards
    static func updateOrCreateNewLocalCard(cardid: NSNumber, question: String, answer: String, cardsets_setid: NSNumber, type: NSNumber, box: NSNumber){
        
        let error: NSError? = nil
        let updateReq: NSBatchUpdateRequest = NSBatchUpdateRequest(entityName: "Cards")
        updateReq.propertiesToUpdate = ["question": question, "answer": answer, "type":type]
        
        let cardidString = String(stringInterpolationSegment: cardid)
        updateReq.predicate = NSPredicate(format: "cardid == %@", cardidString)
        
        updateReq.resultType = .UpdatedObjectsCountResultType
        
        let results = (try! CoreData.sharedInstance.managedObjectContext!.executeRequest(updateReq)) as! NSBatchUpdateResult

        if error == nil {
            if results.result as! Bool == false {
                DLog("Neue Karte wird angelegt")
                createLocalCards(cardid, question: question, answer: answer, cardsets_setid: cardsets_setid, type: type, box: box)
            }else{
                DLog("Karte wurde aktualisiert")
            }
            CoreData.sharedInstance.saveContext()
            //return (results.result as! Bool)
            
        }else{
            DLog("Update Error: \(error?.localizedDescription)")
        }
    }
    
    static func getStatsForCardset(setid: NSNumber) -> Double{
        var stats: Double = 0
        var count: Int = 0
        var steps: Double = 0
        
        let request = NSFetchRequest(entityName: "Cards")
        request.sortDescriptors = [NSSortDescriptor(key: "box", ascending: true), NSSortDescriptor(key: "cardid", ascending: false)]
        request.predicate = NSPredicate(format: "cardsets_setid == %@", setid)
        
        if let allCards = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [Cards] {
            for card in allCards {
                count++
                steps = steps + card.box.doubleValue - 1
            }
            if (count > 0){
                stats = steps/Double(count * BOXCOUNT - count)
            }else{
                stats = 0
            }
        }

        return round(100*stats)/100
    }
    
    static func boxUP(cardid: Int){
        let request = NSFetchRequest(entityName: "Cards")
        let cardidString = String(stringInterpolationSegment: cardid)
        request.predicate = NSPredicate(format: "cardid == %@", cardidString)
        
        if let allCards = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [Cards] {
            for card in allCards {
                let ccard = card as Cards
                if ccard.cardid == cardid {
                    ccard.box = ccard.box.integerValue + 1
                }
            }
        }
        
        CoreData.sharedInstance.saveContext()
    }
    
    static func boxDOWN(cardid: Int){
        let request = NSFetchRequest(entityName: "Cards")
        let cardidString = String(stringInterpolationSegment: cardid)
        request.predicate = NSPredicate(format: "cardid == %@", cardidString)
        
        if let allCards = (try? CoreData.sharedInstance.managedObjectContext?.executeFetchRequest(request)) as? [Cards] {
            for card in allCards {
                let ccard = card as Cards
                if ccard.cardid == cardid {
                    ccard.box = 1
                }
            }
        }
        
        CoreData.sharedInstance.saveContext()
    }
}
