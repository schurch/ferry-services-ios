//
//  PropellerView.swift
//  FerryServices_2
//
//  Created by Stefan Church on 31/12/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class PropellerView: UIView {
    
    // MARK: class overrides
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    // value between 0.0 and 1.0 defining how much of the propeller is drawn
    var percentComplete: Float {
        didSet {
            propellerLayer.strokeEnd = CGFloat(percentComplete)
        }
    }
    
    var color: UIColor {
        didSet {
            propellerLayer.strokeColor = color.CGColor
        }
    }
    
    override var bounds : CGRect {
        didSet {
            redrawPropeller()
        }
    }
    
    override var frame : CGRect {
        didSet {
            redrawPropeller()
        }
    }
    
    var animating: Bool
    
    // MARK: convenience
    var propellerLayer: CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    // MARK: init
    convenience init () {
        self.init(frame:CGRectZero)
    }
    
    override init(frame: CGRect) {
        percentComplete = 0.0
        color = UIColor.lightGrayColor()
        animating = false
        
        super.init(frame: frame)
        
        propellerLayer.strokeColor = self.color.CGColor
        propellerLayer.strokeEnd = CGFloat(self.percentComplete)
        propellerLayer.fillColor = UIColor.clearColor().CGColor
        propellerLayer.lineWidth = 1.0
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: rotation animation
    func startRotating() {
        if animating {
            return
        }
    
        animating = true
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = M_PI * 2
        rotationAnimation.duration = 0.5
        rotationAnimation.cumulative = true
        rotationAnimation.repeatCount = HUGE
        layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")
    }

    func stopRotating() {
        layer.removeAllAnimations()
        animating = false
    }
    
    // MARK: utility methods
    func redrawPropeller() {
        var propellerBezier = UIBezierPath()
        propellerBezier.moveToPoint(CGPointMake(frame.minX + 0.47820 * frame.width, frame.minY + 0.44116 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.52157 * frame.width, frame.minY + 0.44078 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.49228 * frame.width, frame.minY + 0.43628 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.50756 * frame.width, frame.minY + 0.43621 * frame.height))
        propellerBezier.addLineToPoint(CGPointMake(frame.minX + 0.52157 * frame.width, frame.minY + 0.44078 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.52262 * frame.width, frame.minY + 0.43744 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.52189 * frame.width, frame.minY + 0.43966 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.52224 * frame.width, frame.minY + 0.43855 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.78288 * frame.width, frame.minY + 0.23753 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.54030 * frame.width, frame.minY + 0.38610 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.54228 * frame.width, frame.minY + 0.15807 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.96565 * frame.width, frame.minY + 0.42249 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.95262 * frame.width, frame.minY + 0.29358 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.96715 * frame.width, frame.minY + 0.41822 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.75365 * frame.width, frame.minY + 0.51699 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.94998 * frame.width, frame.minY + 0.46734 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.81997 * frame.width, frame.minY + 0.53983 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.56724 * frame.width, frame.minY + 0.51749 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.68963 * frame.width, frame.minY + 0.49495 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.58065 * frame.width, frame.minY + 0.49980 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.54534 * frame.width, frame.minY + 0.55622 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.56460 * frame.width, frame.minY + 0.53199 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.55724 * frame.width, frame.minY + 0.54574 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.54795 * frame.width, frame.minY + 0.55905 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.54624 * frame.width, frame.minY + 0.55714 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.54711 * frame.width, frame.minY + 0.55808 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.59095 * frame.width, frame.minY + 0.88440 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.58358 * frame.width, frame.minY + 0.60003 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.78007 * frame.width, frame.minY + 0.71576 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.33938 * frame.width, frame.minY + 0.95020 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.45755 * frame.width, frame.minY + 1.00337 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.34234 * frame.width, frame.minY + 0.95363 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.36355 * frame.width, frame.minY + 0.71936 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.30838 * frame.width, frame.minY + 0.91421 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.31061 * frame.width, frame.minY + 0.76537 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.45541 * frame.width, frame.minY + 0.55607 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.41615 * frame.width, frame.minY + 0.67363 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.46789 * frame.width, frame.minY + 0.57240 * frame.height))
        propellerBezier.addLineToPoint(CGPointMake(frame.minX + 0.45541 * frame.width, frame.minY + 0.55607 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.44924 * frame.width, frame.minY + 0.54983 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.45325 * frame.width, frame.minY + 0.55415 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.45119 * frame.width, frame.minY + 0.55207 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.43396 * frame.width, frame.minY + 0.51892 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.44129 * frame.width, frame.minY + 0.54068 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.43622 * frame.width, frame.minY + 0.53000 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.43020 * frame.width, frame.minY + 0.51976 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.43272 * frame.width, frame.minY + 0.51923 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.43146 * frame.width, frame.minY + 0.51952 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.12693 * frame.width, frame.minY + 0.39433 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.37690 * frame.width, frame.minY + 0.53012 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.17843 * frame.width, frame.minY + 0.64242 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.19573 * frame.width, frame.minY + 0.14356 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.09061 * frame.width, frame.minY + 0.21931 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.19129 * frame.width, frame.minY + 0.14440 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.38357 * frame.width, frame.minY + 0.27991 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.24241 * frame.width, frame.minY + 0.13471 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.37019 * frame.width, frame.minY + 0.21106 * frame.height))
        propellerBezier.addCurveToPoint(CGPointMake(frame.minX + 0.47820 * frame.width, frame.minY + 0.44116 * frame.height), controlPoint1: CGPointMake(frame.minX + 0.39669 * frame.width, frame.minY + 0.34740 * frame.height), controlPoint2: CGPointMake(frame.minX + 0.45700 * frame.width, frame.minY + 0.44116 * frame.height))
        propellerBezier.addLineToPoint(CGPointMake(frame.minX + 0.47820 * frame.width, frame.minY + 0.44116 * frame.height))
        propellerBezier.closePath()
        
        propellerBezier.miterLimit = 4;

        propellerLayer.path = propellerBezier.CGPath
    }
}
