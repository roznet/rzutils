//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 12/05/2023.
//

import Foundation
import Foundation

extension Array where Element == Double {
    // Sorts the array in ascending order
    func sortedArray() -> [Double] {
        return self.sorted()
    }

    // Function to compute quantile matchin excel R7 method
    public func quantile(_ percentile: Double) -> Double? {
        let sorted = self.sortedArray()
        guard !sorted.isEmpty else { return nil } // Return nil if array is empty
        if sorted.count == 1 { return sorted[0] } // Return the only element if array contains only one element
        
        let h = percentile * (Double(sorted.count) - 1)
        let hFloor = Int(floor(h))
        let hCeil = Int(ceil(h))
        
        if h == Double(hFloor) {
            return sorted[hFloor]
        } else {
            return sorted[hFloor] + (h - Double(hFloor)) * (sorted[hCeil] - sorted[hFloor])
        }
    }
}

extension DataFrame where T == Double {
    
    public enum QuantileInterpolation {
        case linear
        case lowest
        case highest
        case nearest
        case mid
    }
    
    public func quantiles(_ quantiles : [Double], interpolation : QuantileInterpolation = .linear) -> DataFrame<T,T,F> {
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

                switch interpolation {
                case .linear:
                    let h = q * (Double(sorted.count) - 1)
                    let hFloor = Int(floor(h))
                    let hCeil = Int(ceil(h))
                    
                    if h == Double(hFloor) {
                        one.append(sorted[hFloor])
                    } else {
                        one.append(sorted[hFloor] + (h - Double(hFloor)) * (sorted[hCeil] - sorted[hFloor]))
                    }
                case .lowest:
                    let idx = Int(Double(sorted.count) * q)
                    one.append(sorted[idx])
                case .highest:
                    let idx = Int(Double(sorted.count) * q)
                    one.append(sorted[idx+1])
                case .nearest:
                    let idx = Int(Double(sorted.count) * q)
                    if abs(q - Double(idx)) < abs(q - Double(idx+1)) {
                        one.append(sorted[idx])
                    }else{
                        one.append(sorted[idx+1])
                    }
                case .mid:
                    let idx = Int(Double(sorted.count) * q)
                    one.append((sorted[idx] + sorted[idx+1])/2.0)
                }
            }
            calculated[field] = one
        }
        return DataFrame<Double,Double,F>(indexes: quantiles, values: calculated)
    }
    
}


