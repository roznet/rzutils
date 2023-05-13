//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 12/05/2023.
//

import Foundation

extension DataFrame where T == Double {
    
    public func cumsum() -> DataFrame<I,Double,F> {
        var calculated : [F:[Double]] = [:]
        guard self.count > 0 else { return DataFrame<I,T,F>(indexes: [], values: [:]) }
        
        for (field,col) in self.values {
            var cum : [Double] = []
            cum.reserveCapacity(col.count)
            var running : Double = 0.0
            for v in col {
                running += v
                cum.append(running)
            }
            calculated[field] = cum
        }
        return DataFrame<I,Double,F>(indexes: self.indexes, values: calculated)
    }
}
