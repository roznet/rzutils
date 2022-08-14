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
