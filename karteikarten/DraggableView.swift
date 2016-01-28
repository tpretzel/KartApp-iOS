//
//  DraggableView.swift
//
//  Erstellt einen View (Karteikarte) mit den Funktionen zum Karte bewegen, sowie die Aktionen
//  für "gewusst" und "nicht gewusst"
//
//

import Foundation
import UIKit

let ACTION_MARGIN: Float = 120
let SCALE_STRENGTH: Float = 4
let SCALE_MAX:Float = 0.93
let ROTATION_MAX: Float = 1
let ROTATION_STRENGTH: Float = 320
let ROTATION_ANGLE: Float = 3.14/8

protocol DraggableViewDelegate {
    func cardSwipedLeft(card: UIView) -> Void
    func cardSwipedRight(card: UIView) -> Void
    func flip(card: DraggableView) -> Void
    
}

class DraggableView: UIView {
    var delegate: DraggableViewDelegate!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var tapGestureRecognizer: UITapGestureRecognizer!
    var originPoint: CGPoint!
    var overlayView: OverlayView!
    var information: UITextView!
    var answer: UITextView!
    var xFromCenter: Float!
    var yFromCenter: Float!
    var cardID: Int!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    // init: erstelle View (Karteikate) mit subview der Rückseite;
    // gestureRecognizer: erkennt Interaktion mit Touch-Display: pan : ziehen; tap: tippen;
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
        
        
        
        information = UITextView(frame: CGRectMake(self.frame.size.width * 0.1, 50, self.frame.size.width * 0.8, self.frame.size.height*0.8))
        information.text = "no info given"
        information.textAlignment = NSTextAlignment.Center
        information.textColor = UIColor.blackColor()
        information.font = UIFont.systemFontOfSize(14)
        information.editable = false
        information.selectable = false
        information.hidden = false
        
        
        answer = UITextView(frame: CGRectMake(self.frame.size.width * 0.1, 50, self.frame.size.width * 0.8, self.frame.size.height*0.8))
        answer.text = "no info given"
        answer.textAlignment = NSTextAlignment.Center
        answer.textColor = UIColor.blackColor()
        answer.font = UIFont.systemFontOfSize(14)
        answer.editable = false
        answer.selectable = false
        answer.hidden = true
        
        
        self.backgroundColor = UIColor.whiteColor()

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "beingDragged:")
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("flipCard:"))
        tapGestureRecognizer.numberOfTapsRequired = 1
       
        
        self.addGestureRecognizer(panGestureRecognizer)
        self.addGestureRecognizer(tapGestureRecognizer)
        self.addSubview(information)
        self.addSubview(answer)
        
        overlayView = OverlayView(frame: CGRectMake(self.frame.size.width/2-100, 0, 100, 100))
        overlayView.alpha = 0
        self.addSubview(overlayView)

        xFromCenter = 0
        yFromCenter = 0
    }

    func setupView() -> Void {
        self.layer.cornerRadius = 4;
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.2;
        self.layer.shadowOffset = CGSizeMake(1, 1);
    }
    
    // Animation "Karte wird bewegt"
    func beingDragged(gestureRecognizer: UIPanGestureRecognizer) -> Void {
        xFromCenter = Float(gestureRecognizer.translationInView(self).x)
        yFromCenter = Float(gestureRecognizer.translationInView(self).y)
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.Began:
            self.originPoint = self.center
        case UIGestureRecognizerState.Changed:
            let rotationStrength: Float = min(xFromCenter/ROTATION_STRENGTH, ROTATION_MAX)
            let rotationAngle = ROTATION_ANGLE * rotationStrength
            let scale = max(1 - fabsf(rotationStrength) / SCALE_STRENGTH, SCALE_MAX)

            self.center = CGPointMake(self.originPoint.x + CGFloat(xFromCenter), self.originPoint.y + CGFloat(yFromCenter))

            let transform = CGAffineTransformMakeRotation(CGFloat(rotationAngle))
            let scaleTransform = CGAffineTransformScale(transform, CGFloat(scale), CGFloat(scale))
            self.transform = scaleTransform
            self.updateOverlay(CGFloat(xFromCenter))
        case UIGestureRecognizerState.Ended:
            self.afterSwipeAction()
        case UIGestureRecognizerState.Possible:
            fallthrough
        case UIGestureRecognizerState.Cancelled:
            fallthrough
        case UIGestureRecognizerState.Failed:
            fallthrough
        default:
            break
        }
    }
    
    // update View beim Bewegen der Karte
    func updateOverlay(distance: CGFloat) -> Void {
        if distance > 0 {
            overlayView.setMode(GGOverlayViewMode.GGOverlayViewModeRight)
        } else {
            overlayView.setMode(GGOverlayViewMode.GGOverlayViewModeLeft)
        }
        overlayView.alpha = CGFloat(min(fabsf(Float(distance))/100, 0.4))
    }

    // Aktion nach loslassen der Karte 
    // Karte wieder zurück zum Zentrum des Displays oder, wenn weit genug bewegt: Karte wir vom Display entfernt; nächste Karte laden
    func afterSwipeAction() -> Void {
        let floatXFromCenter = Float(xFromCenter)
        if floatXFromCenter > ACTION_MARGIN {
            self.rightAction()
        } else if floatXFromCenter < -ACTION_MARGIN {
            self.leftAction()
        } else {
            UIView.animateWithDuration(0.3, animations: {() -> Void in
                self.center = self.originPoint
                self.transform = CGAffineTransformMakeRotation(0)
                self.overlayView.alpha = 0
            })
        }
    }
    
    // Aktion "gewusst"
   // Karte wird vom Display entfernt --> "gewusst"; nächste Karte laden
    func rightAction() -> Void {
        let finishPoint: CGPoint = CGPointMake(500, 2 * CGFloat(yFromCenter) + self.originPoint.y)
        UIView.animateWithDuration(0.3,
            animations: {
                self.center = finishPoint
            }, completion: {
                (value: Bool) in
                self.removeFromSuperview()
        })
        if examMode == false {
            Stats.writeStats(self.cardID, known: 1)
            Cards.boxUP(self.cardID)
        }
        delegate.cardSwipedRight(self)

    }
    
    // Aktion "nicht gewusst"
    // Karte wird vom Display entfernt --> "nicht gewusst"; nächste Karte laden
    func leftAction() -> Void {
        let finishPoint: CGPoint = CGPointMake(-500, 2 * CGFloat(yFromCenter) + self.originPoint.y)
        UIView.animateWithDuration(0.3,
            animations: {
                self.center = finishPoint
            }, completion: {
                (value: Bool) in
                self.removeFromSuperview()
        })
        if examMode == false {
            Stats.writeStats(self.cardID, known: 0)
            Cards.boxDOWN(self.cardID)
        }
        delegate.cardSwipedLeft(self)
    }

    // Button "gewusst" gedückt
    // Karte wird vom Display entfernt --> "gewusst"; nächste Karte laden
    func rightClickAction() -> Void {
        let finishPoint = CGPointMake(600, self.center.y)
        UIView.animateWithDuration(0.3,
            animations: {
                self.center = finishPoint
                self.transform = CGAffineTransformMakeRotation(1)
            }, completion: {
                (value: Bool) in
                self.removeFromSuperview()
        })
        if examMode == false {
            Stats.writeStats(self.cardID, known: 1)
            Cards.boxUP(self.cardID)
        }
        delegate.cardSwipedRight(self)
    }

    // Button "nicht gewusst" gedückt
    // Karte wird vom Display entfernt --> "nicht gewusst"; nächste Karte laden
    func leftClickAction() -> Void {
        let finishPoint: CGPoint = CGPointMake(-600, self.center.y)
        UIView.animateWithDuration(0.3,
            animations: {
                self.center = finishPoint
                self.transform = CGAffineTransformMakeRotation(1)
            }, completion: {
                (value: Bool) in
                self.removeFromSuperview()
        })
        if examMode == false {
            Stats.writeStats(self.cardID, known: 0)
            Cards.boxDOWN(self.cardID)
        }
        delegate.cardSwipedLeft(self)
    }

    // tippen zum Karte drehen
    func flipCard(sender: UITapGestureRecognizer) -> Void {
        if (sender.state == .Ended){
        delegate.flip(self)
        }

}
}