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
    
    public enum UnitAlignment {
        case hide
        case left
        case right
        case trailingNumber
    }
    
    public enum TimeAlignment {
        case withNumber
        case withUnit
        case center
    }
     
    public enum NumberAlignment {
        case left
        case right
        case decimalSeparator
    }
    
    public enum DisplaySign {
        case natural
        case always
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

    /// Align number on the decimal separator or on the first/last digit
    /// This property affects size calculation
    public var numberAlignment : NumberAlignment = .right
    /// Align time with numbers or units
    /// This property affects size calculation
    public var timeAlignment : TimeAlignment = .center

    /// Alignment of the overall construct
    /// This property does not affects size calculation
    public var alignment : Alignment = .left
    /// Unit position with respect to the number
    /// This property does not affects size calculation
    public var unitAlignment : UnitAlignment = .left
    
    public var sign : DisplaySign = .natural
    
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
        let components = numberWithUnit.formatComponents()
        self.adjust(components: components, numberAttribute: numberAttribute, unitAttribute: unitAttribute)
    }

    private func components<UnitType>(measurement : Measurement<UnitType>,
                            formatter : MeasurementFormatter) -> [String] {
        if self.unitAlignment == .hide {
            let components : [String] = [formatter.numberFormatter.string(from: measurement.value as NSNumber) ?? ""]
            return components
        }else{
            let components : [String] = [formatter.numberFormatter.string(from: measurement.value as NSNumber) ?? "",
                                         formatter.string(from: measurement.unit)]
            return components
        }
    }
    
    private func components<UnitType>(measurement : Measurement<UnitType>,
                            compound : CompoundMeasurementFormatter<UnitType>) -> [String] {
        let components : [String] = [compound.format(from: measurement)]
        return components
    }

    
    public func adjust<UnitType>(measurement : Measurement<UnitType>,
                                 formatter : MeasurementFormatter,
                             numberAttribute : [NSAttributedString.Key:Any]? = nil,
                             unitAttribute : [NSAttributedString.Key:Any]? = nil){
        self.adjust(components: self.components(measurement: measurement, formatter: formatter), numberAttribute: numberAttribute, unitAttribute: unitAttribute)
    }

    public func adjust<UnitType>(measurement : Measurement<UnitType>,
                                 compound : CompoundMeasurementFormatter<UnitType>,
                             numberAttribute : [NSAttributedString.Key:Any]? = nil,
                             unitAttribute : [NSAttributedString.Key:Any]? = nil){
        self.adjust(components: self.components(measurement: measurement, compound: compound), numberAttribute: numberAttribute, unitAttribute: unitAttribute)
    }

    private func adjust(components : [String],
                        numberAttribute : [NSAttributedString.Key:Any]? = nil,
                        unitAttribute : [NSAttributedString.Key:Any]? = nil){
        
        guard var fmtNoUnit = components.first else { return }

        let numberAttribute = numberAttribute ?? self.defaultNumberAttribute
        let unitAttribute = unitAttribute ?? self.defaultUnitAttribute
        
        if self.sign == .always && !fmtNoUnit.hasPrefix("-") {
            fmtNoUnit = "+" + fmtNoUnit
        }
        
        let hasUnit : Bool = components.count == 2
        let fmtUnit = components.last ?? ""

        var numberSize = (fmtNoUnit as NSString).size(withAttributes: numberAttribute)
        var totalSize = numberSize

        let decimalComponents = fmtNoUnit.components(separatedBy: self.decimalSeparatorSet)
        if decimalComponents.count > 1 {
            if let decimalPart = decimalComponents.last {
                let decimalPartSize = (("." + decimalPart) as NSString).size(withAttributes: numberAttribute)
                self.decimalPartSize.max(with: decimalPartSize)
                if case NumberAlignment.decimalSeparator = self.numberAlignment {
                    // this is not exact, but an initial guess as technically we should do a second loop in case
                    // later decimal parts are bigger
                    //      |--|
                    //      123.0
                    //        0.123
                    //         |--|
                    numberSize.width += (self.decimalPartSize.width - decimalPartSize.width)
                }
            }
        }
        
        self.numberSize.max(with: numberSize)
        
        if( hasUnit ){
            let spacingSize = (" " as NSString).size(withAttributes: numberAttribute )
            self.spacingSize.max(with: spacingSize)
            
            let unitSize   = (fmtUnit as NSString).size(withAttributes: unitAttribute)
            self.unitSize.max(with: unitSize)
            
            totalSize.width += (spacingSize.width+unitSize.width)
            totalSize.height = max(totalSize.height, spacingSize.height, unitSize.height)
        }
        
        totalSize.width = self.numberSize.width + self.spacingSize.width + self.unitSize.width
        self.totalSize.max(with: totalSize)
        
        self.accumulatedTotalSize.height += totalSize.height
        self.accumulatedTotalSize.width = max( self.accumulatedTotalSize.width, totalSize.width)
        
        self.count += 1
    }
    
    @discardableResult
    public func drawInRect(_ rect : CGRect,
                           numberWithUnit : GCNumberWithUnit,
                           numberAttribute : [NSAttributedString.Key:Any]? = nil,
                           unitAttribute : [NSAttributedString.Key:Any]? = nil,
                           addUnit : Bool = true,
                           sign: DisplaySign = .natural) -> CGRect {
        let components = numberWithUnit.formatComponents()
        return self.drawInRect(rect, components: components, numberAttribute: numberAttribute, unitAttribute: unitAttribute,
                               addUnit: addUnit, sign: sign, isTime: numberWithUnit.unit.format == gcUnitFormat.time)
    }
    
    @discardableResult
    public func drawInRect<UnitType>(_ rect : CGRect,
                           measurement : Measurement<UnitType>,
                           formatter : MeasurementFormatter,
                           numberAttribute : [NSAttributedString.Key:Any]? = nil,
                           unitAttribute : [NSAttributedString.Key:Any]? = nil,
                           addUnit : Bool = true,
                           sign: DisplaySign = .natural) -> CGRect {
        return self.drawInRect(rect, components: self.components(measurement: measurement, formatter: formatter),
                               numberAttribute: numberAttribute, unitAttribute: unitAttribute,
                               addUnit: addUnit, sign: sign, isTime: false)
    }

    @discardableResult
    public func drawInRect<UnitType>(_ rect : CGRect,
                           measurement : Measurement<UnitType>,
                           compound : CompoundMeasurementFormatter<UnitType>,
                           numberAttribute : [NSAttributedString.Key:Any]? = nil,
                           unitAttribute : [NSAttributedString.Key:Any]? = nil,
                           addUnit : Bool = true,
                           sign: DisplaySign = .natural) -> CGRect {
        return self.drawInRect(rect, components: self.components(measurement: measurement, compound: compound),
                               numberAttribute: numberAttribute, unitAttribute: unitAttribute,
                               addUnit: addUnit, sign: sign, isTime: true)
    }

    @discardableResult
    func drawInRect(_ rect : CGRect,
                    components : [String],
                    numberAttribute : [NSAttributedString.Key:Any]? = nil,
                    unitAttribute : [NSAttributedString.Key:Any]? = nil,
                    addUnit : Bool = true,
                    sign: DisplaySign = .natural,
                    isTime : Bool = false) -> CGRect {

        let unitAttribute = unitAttribute ?? self.defaultUnitAttribute
        let numberAttribute = numberAttribute ?? self.defaultNumberAttribute
        
        var numberPoint = rect.origin
        var unitPoint = rect.origin
        
        guard var fmtNoUnit = components.first else {
            return CGRect.zero
        }
        
        if sign == .always && !fmtNoUnit.hasPrefix("-") {
            fmtNoUnit = "+" + fmtNoUnit
        }
        
        let hasUnit : Bool = components.count == 2
        let fmtUnit = components.last ?? ""

        var currentDecimalPartSize = CGSize.zero
        let decimalComponents = fmtNoUnit.components(separatedBy: self.decimalSeparatorSet)
        if decimalComponents.count > 1 {
            if let decimalPart = decimalComponents.last {
                currentDecimalPartSize = ("." + decimalPart as NSString).size(withAttributes: numberAttribute)
            }
        }

        let currentNumberSize = (fmtNoUnit as NSString).size(withAttributes: numberAttribute)
        let currentUnitSize = (fmtUnit as NSString).size(withAttributes: unitAttribute)
        
        var currentTotalSize = currentNumberSize
        if addUnit && hasUnit {
            currentTotalSize.width += self.spacingSize.width + currentUnitSize.width
            currentTotalSize.height = max( currentTotalSize.height, currentUnitSize.height)
        }
        
        //     |-----||------!
        //       23.2 km
        //        169 km
        //      15:05 min/km
        //         1:20:30

        //   |-------||------!
        //      23.2  km
        //     169    km
        //      15:05 min/km

        //let overflow = rect.size.width - self.totalSize.width
        let overflow = rect.size.width - currentTotalSize.width
        switch alignment {
        case .right:
            unitPoint.x += overflow
            numberPoint.x += overflow
        case .center:
            // center means we center the totalSize in rect
            let totalOverflow = rect.size.width - self.totalSize.width
            unitPoint.x += totalOverflow/2.0
            numberPoint.x += totalOverflow/2.0
        case .left:
            break
        }
        
        // first special case, if center, just center output
        /*if case .center = self.alignment {
            // only move unit at the end of number (center other alignment don't mean much
            unitPoint.x += currentNumberSize.width + spacingSize.width
        }else*/ if !hasUnit && isTime {
            // Second Special case: time
            switch self.timeAlignment {
            case .withUnit:
                numberPoint.x += (currentTotalSize.width - currentNumberSize.width)
            case .center:
                numberPoint.x += (totalSize.width - currentNumberSize.width) / 2.0
            case .withNumber:
                numberPoint.x += (numberSize.width - currentNumberSize.width)
            }
        }else{
            switch self.numberAlignment {
            case .decimalSeparator:
                numberPoint.x += (numberSize.width - currentNumberSize.width) - (decimalPartSize.width - currentDecimalPartSize.width)
            case .left:
                break
            case .right:
                numberPoint.x += (numberSize.width - currentNumberSize.width)
            }
            
            switch unitAlignment {
            case .left:
                unitPoint.x += numberSize.width + self.spacingSize.width
            case .right:
                unitPoint.x += numberSize.width + self.spacingSize.width + (self.unitSize.width - currentUnitSize.width)
            case .trailingNumber:
                unitPoint.x = numberPoint.x + currentNumberSize.width + spacingSize.width
            case .hide:
                // nothing to do
                break
            }
        }
        
        numberPoint.y += (rect.height - currentTotalSize.height) / 2.0
        unitPoint.y += (rect.height - currentTotalSize.height) / 2.0
        
        (fmtNoUnit as NSString).draw(at: numberPoint, withAttributes: numberAttribute)
        if( hasUnit && addUnit ){
            (fmtUnit as NSString).draw(at: unitPoint, withAttributes: unitAttribute)
        }
        return CGRect(origin: numberPoint, size: CGSize(width: currentNumberSize.width+currentUnitSize.width+spacingSize.width, height: currentNumberSize.height ))
    }
}
