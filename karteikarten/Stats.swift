//
//  Stats.swift
//  karteikarten
//
//  Created by D. Vogt on 09.09.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class Stats {
    
    // Statistik in die Online DB übertragen
    static func writeStats(cardid:NSNumber, known:NSNumber){
        
        Session.sharedInstance.ApiManager().request(.POST, apiURL+"/stats/\(cardid)", parameters:["known":known])
            .responseSwiftyJSON({ (request, response, json, error) in
                if (error == nil){
                    
                    DLog("HTTP POST Response: Statistik eingetragen")
                    
                    //self.setLocalStats(formatter.numberFromString(cuser["userid"]!)!, cards_cardid: cardid, known: known)
                }else{
                    DLog("HTTP POST Response: Statistik konnte nicht eingetragen werden")
                }
            })
    }
    
    // Laden der Statistik von der Online DB
    static func getStats(setid:NSNumber){
        
        Session.sharedInstance.ApiManager().request(.GET, apiURL+"/stats/\(setid)")
            .responseSwiftyJSON({ (request, response, json, error) in
                if (error == nil){
                    
                    DLog("HTTP POST Response: Statistik wurde empfangen")
                    
                    //                    self.createLocalStats(formatter.numberFromString(cuser["userid"]!)!, cards_cardid: cardid, known: known)
                }else{
                    DLog("HTTP POST Response: Statistik konnte nicht empfangen werden")
                }
            })
    }
}