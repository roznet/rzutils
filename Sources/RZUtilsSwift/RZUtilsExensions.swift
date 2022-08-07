//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 07/08/2022.
//

import Foundation
import RZUtils

extension GCStatsDataSerie : Sequence {
    public typealias Iterator = NSFastEnumerationIterator
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}
