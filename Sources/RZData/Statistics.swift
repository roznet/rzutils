//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 12/05/2023.
//

import Foundation
import Accelerate

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
    
    public func valueStats(from : I? = nil, to : I? = nil, units : [F:Dimension] = [:], weightsField : F? = nil) -> [F:ValueStats] {
        var rv : [F:ValueStats] = [:]
        
        // Find the range of indexes to process
        let startIdx : Int? = from != nil ? self.indexes.firstIndex(where: { $0 >= from! }) : 0
        let endIdx : Int? = to != nil ? self.indexes.lastIndex(where: { $0 <= to! }) : self.indexes.count - 1

        guard let startIdx = startIdx, let endIdx = endIdx, startIdx <= endIdx else {
            return rv
        }
        
        let range = startIdx...endIdx
        let count = range.count
        
        // Get weights from specified field or use constant 1.0
        var weights = [Double](repeating: 1.0, count: count)
        if let weightsField = weightsField, let weightValues = self.values[weightsField] {
            weights = Array(weightValues[range])
        }
        
        for field in self.fields {
            guard let values = self.values[field] else { continue }
            
            // Extract the range of values we need
            let fieldValues = Array(values[range])
            
            // Calculate basic statistics using Accelerate
            var sum: Double = 0.0
            var sumSquares: Double = 0.0
            var weightedSum: Double = 0.0
            var min: Double = 0.0
            var max: Double = 0.0
            
            // Calculate sum and weighted sum
            vDSP_sveD(fieldValues, 1, &sum, vDSP_Length(count))
            vDSP_dotprD(fieldValues, 1, weights, 1, &weightedSum, vDSP_Length(count))
            
            // Calculate sum of squares
            var squared = [Double](repeating: 0.0, count: count)
            vDSP_vsqD(fieldValues, 1, &squared, 1, vDSP_Length(count))
            vDSP_sveD(squared, 1, &sumSquares, vDSP_Length(count))
            
            // Calculate min/max
            vDSP_minvD(fieldValues, 1, &min, vDSP_Length(count))
            vDSP_maxvD(fieldValues, 1, &max, vDSP_Length(count))
            
            // Calculate total weight
            var totalWeight: Double = 0.0
            vDSP_sveD(weights, 1, &totalWeight, vDSP_Length(count))
            
            // Create ValueStats with the calculated values
            let stats = ValueStats(
                start: fieldValues.first!,
                end: fieldValues.last!,
                sum: sum,
                sumSquare: sumSquares,
                weightedSum: weightedSum,
                max: max,
                min: min,
                count: count,
                weight: totalWeight,
                unit: units[field]
            )
            
            rv[field] = stats
        }
        
        return rv
    }
    
    public func max(for field : F) -> T? {
        guard let fieldValues = self.values[field] else { return nil }
        let value = fieldValues.max()
        return value
    }
    
    public func min(for field : F) -> T? {
        guard let fieldValues = self.values[field] else { return nil }
        let value = fieldValues.min()
        return value
    }

    // MARK: - Accelerate Optimized Statistics
    
    public func sum(for field: F) -> Double? {
        guard let values = self.values[field] else { return nil }
        var result: Double = 0.0
        vDSP_sveD(values, 1, &result, vDSP_Length(values.count))
        return result
    }
    
    public func mean(for field: F) -> Double? {
        guard let values = self.values[field] else { return nil }
        
        // Check for NaN values
        if values.contains(where: { $0.isNaN }) {
            return nil
        }
        
        var result: Double = 0.0
        vDSP_meanvD(values, 1, &result, vDSP_Length(values.count))
        return result
    }
    
    public func variance(for field: F) -> Double? {
        guard let values = self.values[field] else { return nil }
        guard !values.isEmpty else { return nil }
        guard values.count > 1 else { return 0.0 } // Variance is 0 for single value
        
        // Check for NaN values
        if values.contains(where: { $0.isNaN }) {
            return nil
        }
        
        // Calculate mean
        var mean: Double = 0.0
        vDSP_meanvD(values, 1, &mean, vDSP_Length(values.count))
        
        // Calculate sum of squared differences
        var squaredDiffs = [Double](repeating: 0.0, count: values.count)
        let meanArray = [Double](repeating: mean, count: values.count)
        
        // Subtract mean from each value
        vDSP_vsubD(meanArray, 1, values, 1, &squaredDiffs, 1, vDSP_Length(values.count))
        
        // Square the differences
        vDSP_vsqD(squaredDiffs, 1, &squaredDiffs, 1, vDSP_Length(values.count))
        
        // Sum the squared differences
        var sumSquaredDiffs: Double = 0.0
        vDSP_sveD(squaredDiffs, 1, &sumSquaredDiffs, vDSP_Length(values.count))
        
        // Divide by (n-1) for sample variance
        return sumSquaredDiffs / Double(values.count - 1)
    }
    
    public func standardDeviation(for field: F) -> Double? {
        guard let values = self.values[field] else { return nil }
        guard !values.isEmpty else { return nil }
        guard values.count > 1 else { return 0.0 } // Standard deviation is 0 for single value
        
        guard let variance = self.variance(for: field) else { return nil }
        return sqrt(variance)
    }
    
    public func minMax(for field: F) -> (min: Double, max: Double)? {
        guard let values = self.values[field] else { return nil }
        var min: Double = 0.0
        var max: Double = 0.0
        vDSP_minvD(values, 1, &min, vDSP_Length(values.count))
        vDSP_maxvD(values, 1, &max, vDSP_Length(values.count))
        return (min, max)
    }
    
    
    public func movingAverage(for field: F, windowSize: Int) -> [Double]? {
        guard let values = self.values[field], windowSize > 0 else { return nil }
        var result = [Double](repeating: 0.0, count: values.count)
        
        // Use vDSP for efficient moving average calculation
        for i in 0..<values.count {
            let start = Swift.max(0, i - windowSize + 1)
            let count = Swift.min(windowSize, i + 1)
            var sum: Double = 0.0
            vDSP_sveD(Array(values[start..<start+count]), 1, &sum, vDSP_Length(count))
            result[i] = sum / Double(count)
        }
        
        return result
    }
    
    public func correlation(between field1: F, and field2: F) -> Double? {
        guard let values1 = self.values[field1],
              let values2 = self.values[field2],
              values1.count == values2.count,
              !values1.isEmpty else { return nil }
        guard values1.count > 1 else { return 0.0 } // Correlation is 0 for single value
        
        // Check for NaN values
        if values1.contains(where: { $0.isNaN }) || values2.contains(where: { $0.isNaN }) {
            return nil
        }
        
        // Calculate means
        var mean1: Double = 0.0
        var mean2: Double = 0.0
        vDSP_meanvD(values1, 1, &mean1, vDSP_Length(values1.count))
        vDSP_meanvD(values2, 1, &mean2, vDSP_Length(values2.count))
        
        // Create arrays of means
        let meanArray1 = [Double](repeating: mean1, count: values1.count)
        let meanArray2 = [Double](repeating: mean2, count: values2.count)
        
        // Center the values
        var centered1 = [Double](repeating: 0.0, count: values1.count)
        var centered2 = [Double](repeating: 0.0, count: values2.count)
        vDSP_vsubD(meanArray1, 1, values1, 1, &centered1, 1, vDSP_Length(values1.count))
        vDSP_vsubD(meanArray2, 1, values2, 1, &centered2, 1, vDSP_Length(values2.count))
        
        // Calculate covariance numerator
        var covariance: Double = 0.0
        vDSP_dotprD(centered1, 1, centered2, 1, &covariance, vDSP_Length(values1.count))
        
        // Calculate standard deviations
        var sumSquares1: Double = 0.0
        var sumSquares2: Double = 0.0
        var temp1 = centered1
        var temp2 = centered2
        vDSP_vsqD(centered1, 1, &temp1, 1, vDSP_Length(values1.count))
        vDSP_vsqD(centered2, 1, &temp2, 1, vDSP_Length(values2.count))
        vDSP_sveD(temp1, 1, &sumSquares1, vDSP_Length(values1.count))
        vDSP_sveD(temp2, 1, &sumSquares2, vDSP_Length(values2.count))
        
        let stdDev1 = sqrt(sumSquares1 / Double(values1.count - 1))
        let stdDev2 = sqrt(sumSquares2 / Double(values2.count - 1))
        
        // Check for zero standard deviations
        if stdDev1 == 0.0 || stdDev2 == 0.0 {
            return nil
        }
        
        // Calculate correlation
        return covariance / (Double(values1.count - 1) * stdDev1 * stdDev2)
    }
    
    // MARK: - All Fields Statistics
    
    public func sums() -> [F: Double] {
        var results: [F: Double] = [:]
        for field in self.fields {
            results[field] = self.sum(for: field)
        }
        return results
    }
    
    public func means() -> [F: Double] {
        var results: [F: Double] = [:]
        for field in self.fields {
            results[field] = self.mean(for: field)
        }
        return results
    }
    
    public func variances() -> [F: Double] {
        var results: [F: Double] = [:]
        for field in self.fields {
            results[field] = self.variance(for: field)
        }
        return results
    }
    
    public func standardDeviations() -> [F: Double] {
        var results: [F: Double] = [:]
        for field in self.fields {
            results[field] = self.standardDeviation(for: field)
        }
        return results
    }
    
    public func minMaxes() -> [F: (min: Double, max: Double)] {
        var results: [F: (min: Double, max: Double)] = [:]
        for field in self.fields {
            results[field] = self.minMax(for: field)
        }
        return results
    }
    
    public func movingAverages(windowSize: Int) -> [F: [Double]] {
        var results: [F: [Double]] = [:]
        for field in self.fields {
            results[field] = self.movingAverage(for: field, windowSize: windowSize)
        }
        return results
    }
    
    public func correlations() -> [F: [F: Double]] {
        var results: [F: [F: Double]] = [:]
        let fields = self.fields
        
        for field1 in fields {
            var fieldCorrelations: [F: Double] = [:]
            for field2 in fields where field1 != field2 {
                fieldCorrelations[field2] = self.correlation(between: field1, and: field2)
            }
            results[field1] = fieldCorrelations
        }
        
        return results
    }
    
    public func describe() -> [String: [F: Double]] {
        return [
            "sum": sums(),
            "mean": means(),
            "std": standardDeviations(),
            "min": minMaxes().mapValues { $0.min },
            "max": minMaxes().mapValues { $0.max }
        ]
    }
}
    


