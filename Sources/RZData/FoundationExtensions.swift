//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 19/01/2021.
//

import Foundation

extension Collection {
    @inlinable public subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension Calendar {
    public func numberOfNights(from : Date, to: Date) -> Int {
        let fromStart = self.startOfDay(for: from)
        let toStart = self.startOfDay(for: to)
        
        let rv = dateComponents([.day], from: fromStart, to: toStart)
        
        return rv.day!
    }
}

extension Measurement where UnitType : Dimension{
    public var measurementDimension : Measurement<Dimension> { return Measurement<Dimension>(value: self.value, unit: self.unit) }
}

extension DispatchQueue {
    @discardableResult
    public static func synchronized<T>(_ lock: AnyObject, closure:() -> T) -> T {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }

        return closure()
    }


}

extension URLResponse {
    public var stringEncoding : String.Encoding? {
        if let textEncodingName = self.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(textEncodingName as CFString)
            return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
        }
        return nil
    }
}
