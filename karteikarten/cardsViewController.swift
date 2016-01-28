//
//  cardsViewController.swift
//  karteikarten
//
//  Created by D. Vogt on 19.05.15.
//  Copyright (c) 2015 karta.hs-osnabrueck. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData
import HTMLReader


class cardsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CardsProtocol, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var cardsTableView: UITableView!

    // NavBar Titel wird von ViewController geschrieben
    var titelString: String? = nil
    
    var cardid: Int? = nil

    // Pull-Refreah für die TableView
    var refreshControl:UIRefreshControl!

    let cards = Cards(entity: NSEntityDescription.entityForName("Cards",inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!)!, insertIntoManagedObjectContext: CoreData.sharedInstance.managedObjectContext)

    // Fetch von Karten für den gewählten Kartensatze
    private lazy var fetchedResultsController:NSFetchedResultsController! = {
        let request = NSFetchRequest(entityName: "Cards")
        request.sortDescriptors = [NSSortDescriptor(key: "box", ascending: true), NSSortDescriptor(key: "cardid", ascending: false)]
        request.predicate = NSPredicate(format: "cardsets_setid == %@", setid!)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreData.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        return fetchedResultsController

    } ()

    override func viewDidLoad() {
        super.viewDidLoad()

        // NavigationBar Titel anpassen
        let titelNavBar: UILabel = UILabel(frame: CGRectMake(0,0,100,32))
        titelNavBar.textAlignment = .Center
        titelNavBar.text = self.titelString
        self.navigationItem.titleView = titelNavBar

        cards.delegate = self

        self.cardsTableView.backgroundColor = UIColor.clearColor()
        self.cardsTableView.tableFooterView = UIView()

        cardsTableView.dataSource = self
        cardsTableView.delegate = self

        // Pull Methode (runterziehen zum aktualisieren) der Tabelle hinzufügen
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Karten werden aktualisiert")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.cardsTableView.addSubview(refreshControl)

    }

    override func viewWillDisappear(animated: Bool) {
        // Bei verlassen des Controllers das Online Laden der Karten abbrechen
        alreadyLoading = false
    }

    // Bei erneutem öffnen der Kartenansicht, die Karten neu aus der lokalen Datenbank laden
    override func viewWillAppear(animated: Bool) {
        do{
            try fetchedResultsController.performFetch()
        }catch{
            
        }
        self.cardsTableView.reloadData()
    }
    
    func refresh(sender:AnyObject)
    {
        // Pull Refresh nur ausführen, wenn nicht bereits online geladen  wird
        if alreadyLoading == false {
            if Reachability.isConnectedToNetwork() == true {
               cards.loadCards(Int(setid!))
            }else{
                self.refreshControl.endRefreshing()
                MeldungKeinInternet()
            }
        }

    }

    // MARK: Tabellen Funktionen
    // Anzahl der Zellen zurückgeben
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsInSection = fetchedResultsController.sections?[section].numberOfObjects
        return numberOfRowsInSection!
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = cardsTableView.dequeueReusableCellWithIdentifier("cardCell", forIndexPath: indexPath) 
        let card = fetchedResultsController.objectAtIndexPath(indexPath) as! Cards

        // Zellen titel setzen:
        //switch(
        var box: String? = nil
        switch(card.box){
        case 1: box = "1️⃣"
            break
        case 2: box = "2️⃣"
            break
        case 3: box = "3️⃣"
            break
        case 4: box = "4️⃣"
            break
        case 5: box = "5️⃣"
            break
        default: box = ""
        }

        cell.textLabel?.text = "\(box!) \(card.question)"

        return cell
    }

    // Anzahl der Abschnitte in der Tabelle definieren
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let numberOfSections = fetchedResultsController.sections?.count
        return numberOfSections!
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // Sobald Daten in der lokal DB geändert werden, wird die Tabelle neuaufgebaut
        cardsTableView.reloadData()
    }

    // Bei Empfang der Karten aus der online DB
    func didCardsLoad(results: JSON) {
        if(results["error"]){
            DLog(results["message"].stringValue)
        }else{
            // Wenn nicht bereits Daten geladen werden
            alreadyLoading = true
            
            Cards.deleteAllLocalCardsForCardset(Int(setid!)!)
            
            // Für jede empfangene Karte folgendes ausführen
            for index in 0 ..< results["cards"].count {
                if alreadyLoading == false { break }
                let cardid: String? = results["cards"][index]["cardid"].stringValue
                let type: String? = results["cards"][index]["type"].stringValue
                let htmlQuestion: String? = results["cards"][index]["question"].stringValue
                let htmlAnswer: String? = results["cards"][index]["answer"].stringValue
                let setid: String? = results["cards"][index]["cardsets_setid"].stringValue
                let box: String? = results["cards"][index]["box"].stringValue

                // Frage und Antwort in einem HTMLDocument speichern
                let question: HTMLDocument = HTMLDocument(string: htmlQuestion!)
                let answer: HTMLDocument = HTMLDocument(string: htmlAnswer!)

                //Cards.updateOrCreateNewLocalCard(cardid!.toInt()!, question: question.textContent, answer:  answer.textContent, cardsets_setid: setid!.toInt()!, type: type!.toInt()!)
                Cards.createLocalCards(Int(cardid!)!, question: question.textContent, answer: answer.textContent, cardsets_setid: Int(setid!)!, type: Int(type!)!, box: Int(box!)!)

            }

            // Nach Bearbeitung der online Karten die Tabelle neu aufbauen
            alreadyLoading = false
            do{
                try fetchedResultsController.performFetch()
            }catch{
                
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.refreshControl.endRefreshing()
                self.cardsTableView.reloadData()
            })
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Beim tappen auf Lernen, den Titel mit übergeben
        if(segue.identifier == "showLearn"){
            let upcoming: LearnViewController = segue.destinationViewController as! LearnViewController
            let titleString = self.titelString

            upcoming.titelString = titleString
        }
        
        if(segue.identifier == "showCard"){
            let upcoming: CardView = segue.destinationViewController as! CardView
            let indexPath = self.cardsTableView.indexPathForSelectedRow!
            let card = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Cards
            
            upcoming.frage = card.question
            upcoming.antwort = card.answer
        }
        
    }

}
