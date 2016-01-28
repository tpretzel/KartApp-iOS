//
//  Common.swift
//  karteikarten
//
//  Created by D. Vogt on 22.07.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import Foundation
import Alamofire

//App Version
let kVersion: String = "0.92"

// Anzahl BOXEN
let BOXCOUNT: Int = 5

// Prüfungsmodus in den Einstellungen setzen
var examMode: Bool? = false

var cardsToLearn: NSNumber? = nil

// AutoSync in den Einstellungen setzen
var autoSync: Bool? = false

// Benutzer-Dictonary
var cuser = [String:String]()

// Globale Variable für den API-Key
var capikey: String? = nil

// Globale Variable für die
var setid: String? = nil

// Status des Onlline Laden von Daten
var alreadyLoading: Bool? = false

// Einstellung für Alamofire zum setzen des HTTP-Headers
let headers = ["Authorization": capikey!]

// Read URL from Info.plist
let apiURL = NSBundle.mainBundle().objectForInfoDictionaryKey("APIURL") as! String

// ## Farben Deklaration

// UIViews:
var kLightGrey = UIColor(white: 0.97, alpha: 1)

// TableViews:
var kLightBlue = UIColor(red:47/255.0, green: 164/255.0, blue: 240/255.0, alpha: 0.6)

//NavBar:
var kBlue = UIColor(red:47/255.0, green: 164/255.0, blue: 231/255.0, alpha: 1)

// Check the internet connection
public class Reachability {

    class func isConnectedToNetwork()->Bool{

        var Status:Bool = false
        let url = NSURL(string: "http://karta.dima23.de")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0

        var response: NSURLResponse?

        _ = (try? NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)) as NSData?

        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
        }
        return Status
    }
}

// Shuffle Extension
extension Array {
    mutating func shuffle() {
        if count < 2 { return }
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            swap(&self[i], &self[j])
        }
    }
}

// AlertView Methode
func Meldung(title:String, message:String, btnTitle:String){
    let alertView = UIAlertView();
    alertView.addButtonWithTitle(btnTitle);
    UIView.appearance().tintColor = UIColor.blueColor()
    alertView.title = title;
    alertView.message = message;
    alertView.show();
}

// AlertView Keine Internetverbindung
func MeldungKeinInternet(){
    let alertView = UIAlertView();
    alertView.addButtonWithTitle("OK");
    alertView.title = "Fehler!";
    alertView.message = "Es besteht momentan keine Verbindung zum Internet. Bitte versuchen Sie es später erneut.";
    alertView.show();
}

// LOGGING Methods
#if DEBUG
    func DLog(message: String, filename: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        NSLog("%@","[\(filename.lastPathComponent.stringByDeletingPathExtension):\(line)] - \(message)")
        //NSLog("%@","[\(filename.lastPathComponent.stringByDeletingPathExtension):\(line)] \(function) - \(message)")
    }
    #else
    func DLog(message: String, filename: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    }
#endif
func ALog(message: String, filename: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
    NSLog("[\(filename):\(line)] - \(message)")
}

class Session {
    static let sharedInstance = Session()
    
    private var manager : Manager?
    
    func ApiManager()->Manager{
        if let m = self.manager{
            return m
        }else{
            let defaultHeaders = ["Authorization": capikey!]
            
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            configuration.HTTPAdditionalHeaders = defaultHeaders
            
            let tempmanager = Alamofire.Manager(configuration: configuration)
            self.manager = tempmanager
            return self.manager!
        }
    }
}

// #### Code Schnipsel:


// Cards.swift:
//    static func loadCardsInDict(setid: Int) {
//
//        var error: NSError? = nil
//        var fReq: NSFetchRequest = NSFetchRequest(entityName: "Cards")
//
//        ccards.removeAllObjects()
//
//        var setidString = String(stringInterpolationSegment: setid)
//        //fReq.predicate = NSPredicate(format: "cardsets_setid == %@", setidString)
//        //format:"name CONTAINS 'B' "
//
//        var sorter: NSSortDescriptor = NSSortDescriptor(key: "cardid" , ascending: false)
//        fReq.sortDescriptors = [sorter]
//
//        fReq.returnsObjectsAsFaults = false
//
//        var result = CoreData.sharedInstance.managedObjectContext!.executeFetchRequest(fReq, error:&error)
//        for resultItem in result! {
//            var card = resultItem as! Cards
//            if card.cardid == 0 {
//
//            }else{
//                //println(card)
//                if card.cardsets_setid == setid{
//                    ccards.addObject(["cardid":card.cardid, "type":card.type, "question":card.question, "answer":card.answer, "cardsets_set":card.cardsets_setid])
//                }
//            }
//        }
//    }

// ViewController.swift
//    func loadCardsets () {
//
//        ccardsets.removeAllObjects()
//
//        for set in (self.fetchedResultsController.sections?[0] as! NSFetchedResultsSectionInfo).objects {
//
//            var cset = set as! Cardsets
//            //println(cset)
//            if cset.cardsetid != 0{
//                ccardsets.addObject(["cardsetname": cset.cardsetname, "cardsetid": cset.cardsetid])
//            }
//        }
//    }

//func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
    //    var shareAction = UITableViewRowAction(style: .Normal, title: "Share") { (action, indexPath) -> Void in
    //    tableView.editing = false
    //    println("shareAction")
    //    }
    //    shareAction.backgroundColor = UIColor.grayColor()


//    var deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
//    tableView.editing = false
//    println("deleteAction")
//    }
