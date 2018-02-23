//
//  BouncingView.swift
//  YouthGroup
//
//  Created by Adam Zarn on 2/13/18.
//  Copyright © 2018 Adam Zarn. All rights reserved.
//

import Foundation
import UIKit

class BouncingView: UIView {
    
    private let gravity = UIGravityBehavior()
    private let collider: UICollisionBehavior = {
        let collider = UICollisionBehavior()
        collider.translatesReferenceBoundsIntoBoundary = true
        return collider
    }()
    private lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self)
    
    @IBOutlet weak var titleStackView: UIStackView!
    
    private let itemBehavior: UIDynamicItemBehavior = {
        let dib = UIDynamicItemBehavior()
        dib.allowsRotation = false
        dib.elasticity = 0.5
        return dib
    }()
    
    var animating: Bool = false {
        didSet {
            if animating {
                animator.addBehavior(gravity)
                animator.addBehavior(collider)
                animator.addBehavior(itemBehavior)
            } else {
                animator.removeBehavior(gravity)
                animator.removeBehavior(collider)
                animator.removeBehavior(itemBehavior)
            }
        }
    }
    
    func animateTitle() {
        titleStackView.frame.origin = CGPoint.zero
        gravity.addItem(titleStackView)
        collider.addItem(titleStackView)
        itemBehavior.addItem(titleStackView)
    }
    

}

extension UIView {
    func makeCardView() {
        
        self.backgroundColor = .white
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 0.8
        
    }
}
