//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 12/05/2023.
//

import Foundation
import Foundation

extension Array where Element == Double {
    public enum QuantileInterpolationMethod {
        case linear
        case lower
        case higher
        case midpoint
    }
    // Function to compute quantile matchin excel R7 method and matching pandas methods
    public func quantile(_ percentile: Double, method: QuantileInterpolationMethod = .linear) -> Double? {
        let sorted = self.sorted()
        guard !sorted.isEmpty else { return nil } // Return nil if array is empty
        if sorted.count == 1 { return sorted[0] } // Return the only element if array contains only one element
        
        let h = percentile * (Double(sorted.count) - 1)
        let hFloor = Int(floor(h))
        let hCeil = Int(ceil(h))
        
        if h == Double(hFloor) {
            return sorted[hFloor]
        } else {
            switch method {
            case .linear:
                return sorted[hFloor] + (h - Double(hFloor)) * (sorted[hCeil] - sorted[hFloor])
            case .lower:
                return sorted[hFloor]
            case .higher:
                return sorted[hCeil]
            case .midpoint:
                return (sorted[hFloor] + sorted[hCeil]) / 2
            }
        }
    }
}

extension DataFrame where T == Double {
    public typealias QuantileInterpolationMethod = Array<Double>.QuantileInterpolationMethod
    
    public func quantiles(_ quantiles : [Double], interpolation : QuantileInterpolationMethod = .linear) -> DataFrame<T,T,F> {
        var calculated : [F:[Double]] = [:]
        guard self.count > 0 else { return DataFrame<T,T,F>(indexes: [], values: [:]) }
        
        for (field,col) in self.values {
            let sorted = col.sorted()
            var one : [T] = []
            for q in quantiles {
                // if not valid quantile skip
                if q < 0 || q > 1.0 {
                    continue;
                }
                // if only one element, always use it
                if sorted.count == 1 {
                    one.append(sorted[0])
                    continue
                }
                let h = q * (Double(sorted.count) - 1)
                let hFloor = Int(floor(h))
                let hCeil = Int(ceil(h))
                
                if h == Double(hFloor) {
                    one.append( sorted[hFloor] )
                } else {
                    switch interpolation {
                    case .linear:
                        one.append(  sorted[hFloor] + (h - Double(hFloor)) * (sorted[hCeil] - sorted[hFloor]) )
                    case .lower:
                        one.append(  sorted[hFloor] )
                    case .higher:
                        one.append(  sorted[hCeil] )
                    case .midpoint:
                        one.append(  (sorted[hFloor] + sorted[hCeil]) / 2 )
                    }
                }
            }
            calculated[field] = one
        }
        return DataFrame<Double,Double,F>(indexes: quantiles, values: calculated)
    }
    
}


