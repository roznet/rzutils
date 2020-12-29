//
//  GCNumberWithUnit+Geometry.swift
//  RZUtilsSwift
//
//  Created by Brice Rosenzweig on 20/11/2020.
//  Copyright © 2020 Brice Rosenzweig. All rights reserved.
//

import Foundation
import RZUtils

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

extension CGSize {
    mutating func max( with : CGSize ){
        if self.width < with.width {
            self.width = with.width
        }
        if self.height < with.height {
            self.height = with.height
        }
    }
}
@objc public class RZNumberWithUnitGeometry : NSObject {
    
    public enum Alignment {
        case left
        case right
        case center
    }
    
    public enum UnitPosition {
        case aligned
        case withNumber
    }
    
    /// the maximum size of all unit formated
    var unitSize : CGSize = CGSize.zero
    /// the maximum size of all the full numbers
    var numberSize : CGSize = CGSize.zero
    /// the maximum size of all the whole part of all numbers
    var decimalPartSize : CGSize = CGSize.zero
    /// the maximum size of spacing of number, typically size of a space
    var spacingSize : CGSize = CGSize.zero
    /// the maximum size of all the numbers, spacing and units
    public var totalSize : CGSize = CGSize.zero
    /// the accumulated size of all the numbers, spacing and units
    public var accumulatedTotalSize : CGSize = CGSize.zero
    
    public var defaultNumberAttribute : [NSAttributedString.Key:Any] = [:]
    public var defaultUnitAttribute : [NSAttributedString.Key:Any] = [:]
    
    public var alignDecimalPart : Bool = true
    public var alignment : Alignment = .left
    public var unitPosition : UnitPosition = .withNumber
    
    var count : UInt = 0
    
    let decimalSeparatorSet : CharacterSet

    @objc public override init() {
        if let separator = Locale.current.decimalSeparator {
            self.decimalSeparatorSet = CharacterSet(charactersIn: separator + ":" )
        }else{
            self.decimalSeparatorSet = CharacterSet(charactersIn: ".:")
        }
        super.init()
    }
    
    @objc public static func geometry() -> RZNumberWithUnitGeometry {
        return RZNumberWithUnitGeometry()
    }
    
    @objc public func reset() {
        self.unitSize = CGSize.zero
        self.numberSize = CGSize.zero
        self.spacingSize = CGSize.zero
        self.totalSize = CGSize.zero
        self.accumulatedTotalSize = CGSize.zero
        self.count = 0
    }
    
    @objc public func adjust(for numberWithUnit: GCNumberWithUnit,
                             numberAttribute : [NSAttributedString.Key:Any]? = nil,
                             unitAttribute : [NSAttributedString.Key:Any]? = nil){
        
        let unitAttribute = unitAttribute ?? self.defaultUnitAttribute
        let numberAttribute = numberAttribute ?? self.defaultNumberAttribute
        
        
        let components = numberWithUnit.formatComponents()
        guard let fmtNoUnit = components.first else {
            return
        }
        
        let hasUnit : Bool = components.count == 2
        let fmtUnit = numberWithUnit.unit.abbr
        
        let decimalComponents = fmtNoUnit.components(separatedBy: self.decimalSeparatorSet)
        if decimalComponents.count > 1 {
            if let decimalPart = decimalComponents.last {
                let decimalPartSize = (("." + decimalPart) as NSString).size(withAttributes: numberAttribute)
                self.decimalPartSize.max(with: decimalPartSize)
            }
        }
        
        let numberSize = (fmtNoUnit as NSString).size(withAttributes: numberAttribute)
        var totalSize = numberSize
        self.numberSize.max(with: numberSize)
        
        if( hasUnit ){
            let spacingSize = (" " as NSString).size(withAttributes: numberAttribute )
            self.spacingSize.max(with: spacingSize)
            
            let unitSize   = (fmtUnit as NSString).size(withAttributes: unitAttribute)
            self.unitSize.max(with: unitSize)
            
            totalSize.width += (spacingSize.width+unitSize.width)
            totalSize.height = max(totalSize.height, spacingSize.height, unitSize.height)
        }
        
        self.totalSize.max(with: totalSize)
        
        self.accumulatedTotalSize.height += totalSize.height
        self.accumulatedTotalSize.width = max( self.accumulatedTotalSize.width, totalSize.width)
        
        self.count += 1
    }
    
    public func drawInRect(_ rect : CGRect,
                           numberWithUnit : GCNumberWithUnit,
                           numberAttribute : [NSAttributedString.Key:Any]? = nil,
                           unitAttribute : [NSAttributedString.Key:Any]? = nil,
                           addUnit : Bool = true){
        
        let unitAttribute = unitAttribute ?? self.defaultUnitAttribute
        let numberAttribute = numberAttribute ?? self.defaultNumberAttribute
        
        var numberPoint = rect.origin
        var unitPoint = rect.origin
        
        let components = numberWithUnit.formatComponents()
        guard let fmtNoUnit = components.first else {
            return
        }
        
        let hasUnit : Bool = components.count == 2
        let fmtUnit = numberWithUnit.unit.abbr

        var currentDecimalPartSize = CGSize.zero
        let decimalComponents = fmtNoUnit.components(separatedBy: self.decimalSeparatorSet)
        if decimalComponents.count > 1 {
            if let decimalPart = decimalComponents.last {
                currentDecimalPartSize = ("." + decimalPart as NSString).size(withAttributes: numberAttribute)
            }
        }

        let currentNumberSize = (fmtNoUnit as NSString).size(withAttributes: numberAttribute)
        //let currentUnitSize = (fmtUnit as NSString).size(withAttributes: unitAttribute)
        
        //     |-----||------!
        //       23.2 km
        //        169 km
        //      15:05 min/km

        //   |-------||------!
        //      23.2  km
        //     169    km
        //      15:05 min/km

        let overflow = rect.size.width - self.totalSize.width
        switch alignment {
        case .right:
            unitPoint.x += overflow
            numberPoint.x += overflow
        case .center:
            unitPoint.x += overflow/2.0
            numberPoint.x += overflow/2.0
        case .left:
            break
        }
        
        if( hasUnit ){
            unitPoint.x += numberSize.width + self.spacingSize.width
            numberPoint.x += (numberSize.width - currentNumberSize.width)
        }else{
            numberPoint.x += (numberSize.width - currentNumberSize.width)
            // Alternative align for no unit?
            if case UnitPosition.aligned = self.unitPosition {
                numberPoint.x += (totalSize.width - currentNumberSize.width - (unitSize.width/2.0));
            }
        }
        if alignDecimalPart {
            numberPoint.x -= (decimalPartSize.width - currentDecimalPartSize.width)
            unitPoint.x -= (decimalPartSize.width - currentDecimalPartSize.width)
        }
        
        (fmtNoUnit as NSString).draw(at: numberPoint, withAttributes: numberAttribute)
        if( hasUnit && addUnit ){
            (fmtUnit as NSString).draw(at: unitPoint, withAttributes: unitAttribute)
        }

    }
    
    
}
