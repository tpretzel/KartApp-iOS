//
//  DraggableViewBackground.swift
//
//  erstellt LearnViewController
//  lädt einzelne Karten aus DraggableView.swift, speicher diese in ein Array und legt sie als subviews übereinander
//  enthält Buttons für "gewusst" und "nicht gewusst"
//
//

import Foundation
import UIKit
import CoreData

class DraggableViewBackground: UIView, DraggableViewDelegate, NSFetchedResultsControllerDelegate {
    
    var allCards: [DraggableView]!
    
    let MAX_BUFFER_SIZE = 2
    let CARD_HEIGHT: CGFloat = 386
    let CARD_WIDTH: CGFloat = 290
    var knownCards: Int = 0
    var notKnownCards: Int = 0
    var counts: Int! = 0
    
    var currentCard: DraggableView! //NEW
   
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
    
    
    var cardsLoadedIndex: Int!
    
    var loadedCards: [DraggableView]!
   
    var menuButton: UIButton!
    var messageButton: UIButton!
    var checkButton: UIButton!
    var xButton: UIButton!
    var notknownlabel: UILabel! = UILabel()
    var knownlabel: UILabel! = UILabel()
   
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        super.layoutSubviews()
        self.setupView()
        allCards = []
        loadedCards = []
        
        cardsLoadedIndex = 0
        
        self.loadCards()
    }

    // erstellt den Viewcontroller
    func setupView() -> Void {
        self.backgroundColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)

        xButton = UIButton(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + 35, self.frame.size.height/2 + CARD_HEIGHT/2 + 10, 59, 59))
        xButton.setImage(UIImage(named: "xButton"), forState: UIControlState.Normal)
        xButton.addTarget(self, action: "swipeLeft", forControlEvents: UIControlEvents.TouchUpInside)

        // Gewusst Labael
        knownCards = 0
        knownlabel.frame = CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + 35, self.frame.size.height/2 - 80, self.frame.size.width-20, 40)
        knownlabel.textAlignment = NSTextAlignment.Left
        knownlabel.text = "\(knownCards) Karten gewusst"
        knownlabel.textColor = UIColor.blackColor()
        knownlabel.hidden = false
        
        // Nicht gewusst Labael
        notKnownCards = 0
        notknownlabel.frame = CGRectMake((self.frame.size.width - CARD_WIDTH)/2 + 35, self.frame.size.height/2 - 40, self.frame.size.width-20, 40)
        notknownlabel.textAlignment = NSTextAlignment.Left
        notknownlabel.text = "\(notKnownCards) Karten nicht gewusst"
        notknownlabel.textColor = UIColor.redColor()
        notknownlabel.hidden = false
        
        checkButton = UIButton(frame: CGRectMake(self.frame.size.width/2 + CARD_WIDTH/2 - 85, self.frame.size.height/2 + CARD_HEIGHT/2 + 10, 59, 59))
        checkButton.setImage(UIImage(named: "checkButton"), forState: UIControlState.Normal)
        checkButton.addTarget(self, action: "swipeRight", forControlEvents: UIControlEvents.TouchUpInside)

        self.addSubview(xButton)
        self.addSubview(checkButton)
        self.addSubview(knownlabel)
        self.addSubview(notknownlabel)
    }
    
    // erstelle Karte aus DraggableView.swift
    func createDraggableViewWithDataAtIndex(index: NSInteger) -> DraggableView {
        let draggableView = DraggableView(frame: CGRectMake((self.frame.size.width - CARD_WIDTH)/2, (self.frame.size.height - CARD_HEIGHT)/2, CARD_WIDTH, CARD_HEIGHT))
        let card = self.fetchedResultsController.sections![0].objects![index] as! Cards
        draggableView.cardID = card.cardid as Int
        draggableView.information.text = card.question
        draggableView.answer.text = card.answer
        draggableView.delegate = self
        return draggableView
    }
    
    // lädt alle Karten eines Kartensatzes
    // führt createDraggableViewWithDataAtIndex für jede Karte aus
    func loadCards() -> Void {
        let counts: Int! = self.fetchedResultsController.fetchedObjects?.count
        if counts > 0 {
            let numLoadedCardsCap = counts > MAX_BUFFER_SIZE ? MAX_BUFFER_SIZE : counts
            for var i = 0; i < counts; i++ {
                let newCard: DraggableView! = self.createDraggableViewWithDataAtIndex(i)
                
                
                allCards.append(newCard)
                
//                if i < numLoadedCardsCap {
//                    loadedCards.append(newCard)
//                    
//                }
            }
            
            if examMode == true{
                
                //shuffle
                allCards.shuffle()
            }

            for var i = 0; i < numLoadedCardsCap; i++ {
                loadedCards.append(allCards[i])
                
            }
            
            for var i = 0; i < loadedCards.count; i++ {
                if i > 0 {
                    self.insertSubview(loadedCards[i], belowSubview: loadedCards[i - 1])
                } else {
                    self.addSubview(loadedCards[i])
                }
                
                cardsLoadedIndex = cardsLoadedIndex + 1
            }
            
        }
        
    }

    // löscht karte aus Array, wenn bearbeitet
    func cardSwipedLeft(card: UIView) -> Void {
        loadedCards.removeAtIndex(0)
        incNotKnown()
        if cardsLoadedIndex < allCards.count {
            loadedCards.append(allCards[cardsLoadedIndex])
            cardsLoadedIndex = cardsLoadedIndex + 1
            self.insertSubview(loadedCards[MAX_BUFFER_SIZE - 1], belowSubview: loadedCards[MAX_BUFFER_SIZE - 2])
        }
    }
    
    // löscht karte aus Array, wenn bearbeitet
    func cardSwipedRight(card: UIView) -> Void {
        loadedCards.removeAtIndex(0)
        incKnown()
        if cardsLoadedIndex < allCards.count {
            loadedCards.append(allCards[cardsLoadedIndex])
            cardsLoadedIndex = cardsLoadedIndex + 1
            self.insertSubview(loadedCards[MAX_BUFFER_SIZE - 1], belowSubview: loadedCards[MAX_BUFFER_SIZE - 2])
        }
    }

    // Lädt nächsten View beim bewegen der Karte
    // führt Aktion für "gewusst" aus
    func swipeRight() -> Void {
        if loadedCards.count <= 0 {
            return
        }
        let dragView: DraggableView = loadedCards[0]
        dragView.overlayView.setMode(GGOverlayViewMode.GGOverlayViewModeRight)
        UIView.animateWithDuration(0.2, animations: {
            () -> Void in
            dragView.overlayView.alpha = 1
        })
        dragView.rightClickAction()
    }

    // Lädt nächsten View beim bewegen der Karte
    // führt Aktion für "nicht gewusst" aus
    func swipeLeft() -> Void {
        if loadedCards.count <= 0 {
            return
        }
        let dragView: DraggableView = loadedCards[0]
        dragView.overlayView.setMode(GGOverlayViewMode.GGOverlayViewModeLeft)
        UIView.animateWithDuration(0.2, animations: {
            () -> Void in
            dragView.overlayView.alpha = 1
        })
        dragView.leftClickAction()
    }
    
    // dreht Karte
    // setzte Frage bzw. Antwort auf hidden und führt Animation aus
    func flip(card: DraggableView) -> Void {
        if (card.answer.hidden == true){
            
            card.answer.hidden = false
            card.information.hidden = true

            UIView.transitionFromView(card.information, toView: card.answer , duration: 0.7, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
                } else
        {
            card.answer.hidden = true
            card.information.hidden = false

            UIView.transitionFromView(card.answer, toView: card.information , duration: 0.7, options: UIViewAnimationOptions.TransitionFlipFromLeft, completion: nil)}
    }
    
    // zählt gewusste Karten zum Anezigen einer Statistik am Ende des Lernvorgangs
    func incKnown(){
        knownCards++
        knownlabel.text = "\(knownCards) Karten gewusst"
        if loadedCards.count == 0 {
            xButton.hidden = true
            checkButton.hidden = true
        }
    }
    
    // zählt nicht gewusste Karten zum Anezigen einer Statistik am Ende des Lernvorgangs
    func incNotKnown(){
        if notKnownCards >= 0 {
            notKnownCards++
            notknownlabel.text = "\(notKnownCards) Karten nicht gewusst"
        }
        
        if loadedCards.count == 0 {
            xButton.hidden = true
            checkButton.hidden = true
        }
    }
    
    // setzt Statistik des Lernvorgangs zurück
    func resetKnown(){
        knownCards = 0
        notKnownCards = 0
        xButton.hidden = false
        checkButton.hidden = false
        cardsLoadedIndex = 0
        notKnownCards = 0
        knownCards = 0
    }
}

  
    



