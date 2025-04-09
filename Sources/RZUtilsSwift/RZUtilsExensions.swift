//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 07/08/2022.
//

import Foundation
import RZUtils

extension GCStatsDataSerie : @retroactive Sequence {
    public typealias Iterator = NSFastEnumerationIterator
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

extension GCNumberWithUnit : @retroactive Comparable {
    
    public static func < (lhs: GCNumberWithUnit, rhs: GCNumberWithUnit) -> Bool {
        return lhs.compare(rhs) == ComparisonResult.orderedAscending
    }
}

extension GCNumberWithUnit {
    enum GCNumberWithUnitError : Error {
        case incompatibleUnit
    }
    public static func +(lhs: GCNumberWithUnit, rhs: GCNumberWithUnit) throws -> GCNumberWithUnit {
        if let rv = lhs.add(rhs, weight: 1.0) {
            return rv
        }
        throw GCNumberWithUnitError.incompatibleUnit
    }
    
    public static func -(lhs: GCNumberWithUnit, rhs: GCNumberWithUnit) throws -> GCNumberWithUnit {
        if let rv = lhs.add(rhs, weight: -1.0) {
            return rv
        }
        throw GCNumberWithUnitError.incompatibleUnit
    }
    
    public static prefix func -(nu: GCNumberWithUnit) throws -> GCNumberWithUnit {
        if let rv = nu.numberWithUnitMultiplied(by: -1.0) {
            return rv
        }
        throw GCNumberWithUnitError.incompatibleUnit
    }
}
