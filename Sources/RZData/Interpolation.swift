//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 14/05/2023.
//

import Foundation
import Accelerate

extension DataFrame where T == Double, I == Double {
    /// Interpolates values at the given indexes using linear interpolation
    /// - Parameter indexes: The target indexes to interpolate values at
    /// - Returns: A new DataFrame with interpolated values
    public func interpolate(indexes: [I]) -> DataFrame {
        guard !self.indexes.isEmpty else { return DataFrame(fields: self.fields) }
        
        var interpolatedValues: [F: [T]] = [:]
        let fields = self.fields
        
        // Pre-allocate arrays for each field
        for field in fields {
            interpolatedValues[field] = [T](repeating: 0.0, count: indexes.count)
        }
        
        // For each target index
        for (i, targetIndex) in indexes.enumerated() {
            // Find the surrounding points for interpolation
            let lowerIndex = self.indexes.lastIndex { $0 <= targetIndex } ?? 0
            let upperIndex = self.indexes.firstIndex { $0 >= targetIndex } ?? (self.indexes.count - 1)
            
            // Handle edge cases
            if lowerIndex == upperIndex {
                // Exact match or edge case
                for field in fields {
                    interpolatedValues[field]?[i] = self.values[field]?[lowerIndex] ?? 0.0
                }
            } else {
                // Linear interpolation
                let x0 = self.indexes[lowerIndex]
                let x1 = self.indexes[upperIndex]
                let t = (targetIndex - x0) / (x1 - x0)
                
                for field in fields {
                    if let values = self.values[field],
                       lowerIndex < values.count && upperIndex < values.count {
                        let y0 = values[lowerIndex]
                        let y1 = values[upperIndex]
                        interpolatedValues[field]?[i] = y0 + t * (y1 - y0)
                    }
                }
            }
        }
        
        return DataFrame(indexes: indexes, values: interpolatedValues)
    }
}

extension DataFrame where T == Double, I == Date {
    /// Interpolates values at the given dates using time-based linear interpolation
    /// - Parameter dates: The target dates to interpolate values at
    /// - Returns: A new DataFrame with interpolated values
    public func interpolate(dates: [I]) -> DataFrame {
        guard !self.indexes.isEmpty else { return DataFrame(fields: self.fields) }
        
        var interpolatedValues: [F: [T]] = [:]
        let fields = self.fields
        
        // Pre-allocate arrays for each field
        for field in fields {
            interpolatedValues[field] = [T](repeating: 0.0, count: dates.count)
        }
        
        // Convert dates to time intervals for easier calculation
        let targetIntervals = dates.map { $0.timeIntervalSince1970 }
        let sourceIntervals = self.indexes.map { $0.timeIntervalSince1970 }
        
        // For each target date
        for (i, targetInterval) in targetIntervals.enumerated() {
            // Find the surrounding points for interpolation
            let lowerIndex = sourceIntervals.lastIndex { $0 <= targetInterval } ?? 0
            let upperIndex = sourceIntervals.firstIndex { $0 >= targetInterval } ?? (sourceIntervals.count - 1)
            
            // Handle edge cases
            if lowerIndex == upperIndex {
                // Exact match or edge case
                for field in fields {
                    interpolatedValues[field]?[i] = self.values[field]?[lowerIndex] ?? 0.0
                }
            } else {
                // Linear interpolation
                let x0 = sourceIntervals[lowerIndex]
                let x1 = sourceIntervals[upperIndex]
                let t = (targetInterval - x0) / (x1 - x0)
                
                for field in fields {
                    if let values = self.values[field],
                       lowerIndex < values.count && upperIndex < values.count {
                        let y0 = values[lowerIndex]
                        let y1 = values[upperIndex]
                        interpolatedValues[field]?[i] = y0 + t * (y1 - y0)
                    }
                }
            }
        }
        
        return DataFrame(indexes: dates, values: interpolatedValues)
    }
}
