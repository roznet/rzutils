//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 12/05/2023.
//

import Foundation
import Accelerate

extension DataFrame where T == Double {
    
    public func cumsum() -> DataFrame<I,Double,F> {
        var calculated : [F:[Double]] = [:]
        guard self.count > 0 else { return DataFrame<I,T,F>(indexes: [], values: [:]) }
        
        for (field,col) in self.values {
            var cum : [Double] = [Double](repeating: 0.0, count: col.count)
            guard col.count > 0 else { continue }
            
            // First element is just the first value
            cum[0] = col[0]
            
            for i in 1..<col.count {
                cum[i] = cum[i-1] + col[i]
            }
            
            calculated[field] = cum
        }
        return DataFrame<I,Double,F>(indexes: self.indexes, values: calculated)
    }
}
