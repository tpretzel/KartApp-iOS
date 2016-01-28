//
//  ViewController.swift
//  
//  Die Start-Ansicht in der alle Kartensätze angezeigt werden
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData
import HTMLReader

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, CardsetsProtocol{

    @IBOutlet weak var cardSetTableView: UITableView!
    @IBOutlet weak var syncLabel: UILabel!
    
    var titleString: String? = nil
    var refreshControl: UIRefreshControl!
    let dateFormatter = NSDateFormatter()
    let cardset = Cardsets(entity: NSEntityDescription.entityForName("Cardsets",inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!)!, insertIntoManagedObjectContext: CoreData.sharedInstance.managedObjectContext)
    let cards = Cards(entity: NSEntityDescription.entityForName("Cards",inManagedObjectContext: CoreData.sharedInstance.managedObjectContext!)!, insertIntoManagedObjectContext: CoreData.sharedInstance.managedObjectContext)

    // FRC-Cardsets Alle Kartensätze fetchen
    private lazy var fetchedResultsController:NSFetchedResultsController! = {
        let request = NSFetchRequest(entityName: "Cardsets")
        request.sortDescriptors = [NSSortDescriptor(key: "cardsetid", ascending: true)]
        request.predicate = NSPredicate(format: "cardsetid != nil")
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

        // Anpassungen der NavigationBar
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController!.navigationBar.translucent = true
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.backgroundColor = UIColor(red:47/255.0, green: 164/255.0, blue: 231/255.0, alpha: 1)
        
        // NavBar Button Left: Username
        self.navigationItem.leftBarButtonItem?.title = " ☰ " + cuser["username"]!.uppercaseString
        
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        
        // Logo in der Mitte
        let image : UIImage = UIImage(named: "cards")!
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 49, height: 35))
        imageView.contentMode = .ScaleAspectFit
        imageView.image = image
        self.navigationItem.titleView = imageView

        // Aussehen der Tabelle anpassen
        let inset: UIEdgeInsets = UIEdgeInsetsMake(5, 0, 0, 0);
        self.cardSetTableView.contentInset = inset
        self.cardSetTableView.backgroundColor = UIColor.clearColor()
        self.cardSetTableView.tableFooterView = UIView()
        self.cardSetTableView.separatorInset = inset

        // Pull Methode (runterziehen zum aktualisieren) der Tabelle hinzufügen
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Kartensätze werden aktualisiert")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.cardSetTableView.addSubview(refreshControl)

        // Kartensätze online laden
        if autoSync! { if Reachability.isConnectedToNetwork() == true { cardset.getAllCardsets() } }
        
        cardset.delegate = self

        // This tells the table view that it should get it's data from this class, ViewController
        cardSetTableView.dataSource = self
        cardSetTableView.delegate = self
        
        cardSetTableView.reloadData()
    }

    // Bei erneutem öffnen die Kartensätze neuladen
    override func viewWillAppear(animated: Bool) {
//        if autoSync! { if Reachability.isConnectedToNetwork() == true { cardset.getAllCardsets() } }
//        cardSetTableView.reloadData()
    }

    // MARK: RefreshControl
    // Pull Methode (runterziehen zum aktualisieren)
    func refresh(sender:AnyObject){
        if alreadyLoading == false {
            if Reachability.isConnectedToNetwork() == true {
                cardset.getAllCardsets()
            }else{
                self.refreshControl.endRefreshing()
                MeldungKeinInternet()
            }
        }
    }

    // Bei Änderungen an der Datenbank, die Tabellendaten neuladen
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        cardSetTableView.reloadData()
    }

    // MARK: Tabellen Funktionen
    // Anzahl der Zellen zurückgeben
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsInSection = fetchedResultsController.sections?[section].numberOfObjects
        return numberOfRowsInSection!
    }

    // Zellen Eigenschaften Definition
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = cardSetTableView.dequeueReusableCellWithIdentifier("setcell", forIndexPath: indexPath) as! CardsetCell
        let cardset = fetchedResultsController.objectAtIndexPath(indexPath) as! Cardsets

        if cardset.cardsetid != 0{
            
            if cardset.cardsetid == 83 {
                cell.cardsetName.text = "🌎 \(cardset.cardsetname)"
            }else{
                cell.cardsetName.text = cardset.cardsetname
            }
            
            self.syncLabel.text = "Letzte Synchronisierung: " + dateFormatter.stringFromDate(cardset.syncdate)
            
            if cardset.permission == 0 {
                cell.permission.text = "" //👤
            }else{
                cell.permission.text = "👥"
            }
            
            // Anzahl Karten des aktuellen Kartensatzes auslesen
            let anzCards = fetchCardsForCardset(cardset.cardsetid.stringValue)
            
            let stats = Cards.getStatsForCardset(cardset.cardsetid)
            
            cell.cardsetSubtitle.text = "\(anzCards) Karten"
            cell.progressBar.setProgress(Float(stats), animated: false)
            cell.progressLabel.text = String(format: "%.0f%@", stats*100,"%")
    
            cell.contentView.layer.cornerRadius = 12
            cell.contentView.layer.masksToBounds = true
            
        }else{
            cardset.delete()
        }
        
        return cell
    }

    // Bei Tappen auf einen Kartensatz, die Karten des Kartensatzes anzeigen
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showCards", sender: self)
    }

    // Anzahl der Abschnitte in der Tabelle definieren
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let numberOfSections = fetchedResultsController.sections?.count
        return numberOfSections!
    }

    // Zellen einrücken
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        let inset: UIEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        cell.separatorInset = inset
    }

    // Lernen und + Button dem Kartensatz hinzufügen
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let doneAction = UITableViewRowAction(style: .Default, title: "Lernen") { (action, indexPath) -> Void in
        tableView.editing = false

            self.titleString = self.fetchedResultsController.objectAtIndexPath(indexPath)["cardsetname"] as? String
            let set = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Cardsets
            setid = set.cardsetid.stringValue
            self.titleString = set.cardsetname
            
            self.performSegueWithIdentifier("Learn", sender: self)
        }
        doneAction.backgroundColor = self.view.backgroundColor
        
        let shareAction = UITableViewRowAction(style: .Normal, title: "➕") { (action, indexPath) -> Void in
        tableView.editing = false
            
            self.titleString = self.fetchedResultsController.objectAtIndexPath(indexPath)["cardsetname"] as? String
            let set = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Cardsets
            setid = set.cardsetid.stringValue
            self.titleString = set.cardsetname
            
            self.performSegueWithIdentifier("shareView", sender: self)
        }
        shareAction.backgroundColor = self.view.backgroundColor

        return [doneAction, shareAction]
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "showCards"){
            let upcoming: cardsViewController = segue.destinationViewController as! cardsViewController
            let indexPath = self.cardSetTableView.indexPathForSelectedRow!
            let cardset = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Cardsets

            upcoming.titelString = cardset.cardsetname
            setid = cardset.cardsetid.stringValue

            self.cardSetTableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        if(segue.identifier == "Learn"){
            let upcoming: LearnViewController = segue.destinationViewController as! LearnViewController
            upcoming.titelString = self.titleString
        }
        
        if(segue.identifier == "shareView"){
            let upcoming: ShareVC = segue.destinationViewController as! ShareVC
            upcoming.titelString = self.titleString
        }
    }

    // Bei erolgreicher Verbindung zur Online-DB
    // und ausführen des Laden der Kartensätze inkl Karten
    func didCardsetsLoad(results: JSON){
        if(results["error"]){
            //
        }else{
            Cardsets.deleteAllLocalCardsets()
            Cards.deleteAllLocalCards()
            
            for index in 0 ..< results["cardsets"].count {
                let name: String? = results["cardsets"][index]["name"].stringValue
                let id: String? = results["cardsets"][index]["setid"].stringValue
                let permission: String? = results["cardsets"][index]["permission"].stringValue
                
                Cardsets.createLocalCardsets(Int(id!)!, cardsetname: name!, permission: Int(permission!)!)
                
                // Für jede empfangene Karte folgendes ausführen
                for cardindex in 0 ..< results["cardsets"][index]["cards"].count {
                    
                    let cardid: String? = results["cardsets"][index]["cards"][cardindex]["cardid"].stringValue
                    let type: String? = results["cardsets"][index]["cards"][cardindex]["type"].stringValue
                    let htmlQuestion: String? = results["cardsets"][index]["cards"][cardindex]["question"].stringValue
                    let htmlAnswer: String? = results["cardsets"][index]["cards"][cardindex]["answer"].stringValue
                    let setid: String? = results["cardsets"][index]["cards"][cardindex]["cardsets_setid"].stringValue
                    let box: String? = results["cardsets"][index]["cards"][cardindex]["box"].stringValue
                    
                    let question: HTMLDocument = HTMLDocument(string: htmlQuestion!)
                    let answer: HTMLDocument = HTMLDocument(string: htmlAnswer!)
//                    let question = htmlQuestion!
//                    let answer = htmlAnswer!

                    //Cards.createLocalCards(cardid!.toInt()!, question: question.textContent, answer: answer.textContent, cardsets_setid: setid!.toInt()!, type: type!.toInt()!, box: box!.toInt()!)
                    Cards.createLocalCards(Int(cardid!)!, question: question.textContent, answer: answer.textContent, cardsets_setid: Int(setid!)!, type: Int(type!)!, box: Int(box!)!)
                }
            }
            
            CoreData.sharedInstance.saveContext()
            
            self.refreshControl.endRefreshing()
            self.cardSetTableView.reloadData()
        }
    }

    // Reload-Button in der rechten Ecke, führt die Methode vom refreshControl aus
    @IBAction func refreshButtonTapped(sender: AnyObject) {
        self.refresh(self)
    }
    
    // Anzahl der Karten pro Kartensatz auslesen
    private func fetchCardsForCardset(setid: String) -> Int{
        // FRC-Cardsets Alle Kartensätze fetchen
        var countCards: Int? = nil
        
        let fetchAllCards:NSFetchedResultsController! = {
            let request = NSFetchRequest(entityName: "Cards")
            request.sortDescriptors = [NSSortDescriptor(key: "cardid", ascending: true)]
            request.predicate = NSPredicate(format: "cardid != nil AND cardsets_setid = %@", setid)
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreData.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            do {
                try fetchedResultsController.performFetch()
            } catch _ {
            }
            return fetchedResultsController
            } ()
        
        countCards = fetchAllCards.sections![0].objects!.count
        
        return countCards!
    }
}
