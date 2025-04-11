//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 14/05/2023.
//

import Foundation
import Accelerate

public enum InterpolationMethod {
    /// Linear interpolation between points
    case linear
    /// Cubic spline interpolation, providing smooth curves through all points
    case cubicSpline
}
extension DataFrame where T == Double, I == Double {
    /// Defines the available interpolation methods
    
    /// Interpolates values at the given indexes using the specified interpolation method
    /// - Parameters:
    ///   - indexes: The target indexes to interpolate values at
    ///   - method: The interpolation method to use (default: .linear)
    /// - Returns: A new DataFrame with interpolated values
    public func interpolate(indexes: [I], method: InterpolationMethod = .linear) -> DataFrame {
        switch method {
        case .linear:
            return linearInterpolate(indexes: indexes)
        case .cubicSpline:
            return cubicSplineInterpolate(indexes: indexes)
        }
    }
    
    private func linearInterpolate(indexes: [I]) -> DataFrame {
        guard !self.indexes.isEmpty else { return DataFrame(fields: self.fields) }
        
        var interpolatedValues: [F: [T]] = [:]
        let fields = self.fields
        
        // Pre-allocate arrays for each field
        for field in fields {
            interpolatedValues[field] = [T](repeating: 0.0, count: indexes.count)
        }
        
        // Pre-compute the intervals for each target index
        var lowerIndices = [Int](repeating: 0, count: indexes.count)
        var upperIndices = [Int](repeating: 0, count: indexes.count)
        var tValues = [T](repeating: 0.0, count: indexes.count)
        
        // Find surrounding points and compute interpolation coefficients
        for (i, targetIndex) in indexes.enumerated() {
            let lowerIndex = self.indexes.lastIndex { $0 <= targetIndex } ?? 0
            let upperIndex = self.indexes.firstIndex { $0 >= targetIndex } ?? (self.indexes.count - 1)
            
            lowerIndices[i] = lowerIndex
            upperIndices[i] = upperIndex
            
            if lowerIndex == upperIndex {
                tValues[i] = 0.0 // Will be handled separately
            } else {
                let x0 = self.indexes[lowerIndex]
                let x1 = self.indexes[upperIndex]
                tValues[i] = (targetIndex - x0) / (x1 - x0)
            }
        }
        
        // For each field, perform vectorized interpolation
        for field in fields {
            guard let values = self.values[field] else { continue }
            
            // Pre-allocate arrays for vectorized operations
            var y0 = [T](repeating: 0.0, count: indexes.count)
            var y1 = [T](repeating: 0.0, count: indexes.count)
            var result = [T](repeating: 0.0, count: indexes.count)
            
            // Extract y0 and y1 values
            for i in 0..<indexes.count {
                y0[i] = values[lowerIndices[i]]
                y1[i] = values[upperIndices[i]]
            }
            
            // Compute y1 - y0
            var yDiff = [T](repeating: 0.0, count: indexes.count)
            vDSP_vsubD(y0, 1, y1, 1, &yDiff, 1, vDSP_Length(indexes.count))
            
            // Compute t * (y1 - y0)
            var tTimesDiff = [T](repeating: 0.0, count: indexes.count)
            vDSP_vmulD(tValues, 1, yDiff, 1, &tTimesDiff, 1, vDSP_Length(indexes.count))
            
            // Compute y0 + t * (y1 - y0)
            vDSP_vaddD(y0, 1, tTimesDiff, 1, &result, 1, vDSP_Length(indexes.count))
            
            // Handle exact matches (where t = 0)
            for i in 0..<indexes.count where lowerIndices[i] == upperIndices[i] {
                result[i] = values[lowerIndices[i]]
            }
            
            interpolatedValues[field] = result
        }
        
        return DataFrame(indexes: indexes, values: interpolatedValues)
    }
    
    private func cubicSplineInterpolate(indexes: [I]) -> DataFrame {
        guard !self.indexes.isEmpty else { return DataFrame(fields: self.fields) }
        
        var interpolatedValues: [F: [T]] = [:]
        let fields = self.fields
        
        // Pre-allocate arrays for each field
        for field in fields {
            interpolatedValues[field] = [T](repeating: 0.0, count: indexes.count)
        }
        
        // For each field, compute cubic spline coefficients and interpolate
        for field in fields {
            guard let values = self.values[field] else { continue }
            
            // Compute second derivatives using Accelerate
            var secondDerivatives = [T](repeating: 0.0, count: self.indexes.count)
            computeCubicSplineCoefficients(x: self.indexes, y: values, y2: &secondDerivatives)
            
            // Interpolate using the coefficients
            for (i, targetIndex) in indexes.enumerated() {
                interpolatedValues[field]?[i] = evaluateCubicSpline(
                    x: self.indexes,
                    y: values,
                    y2: secondDerivatives,
                    target: targetIndex
                )
            }
        }
        
        return DataFrame(indexes: indexes, values: interpolatedValues)
    }
    
    private func computeCubicSplineCoefficients(x: [T], y: [T], y2: inout [T]) {
        let n = x.count
        var u = [T](repeating: 0.0, count: n-1)
        
        // Natural spline conditions
        y2[0] = 0
        y2[n-1] = 0
        
        // Compute differences using Accelerate
        var h = [T](repeating: 0.0, count: n-1)
        var delta = [T](repeating: 0.0, count: n-1)
        
        // Compute h and delta using vDSP
        x.withUnsafeBufferPointer { xPtr in
            y.withUnsafeBufferPointer { yPtr in
                vDSP_vsubD(xPtr.baseAddress!, 1, xPtr.baseAddress! + 1, 1, &h, 1, vDSP_Length(n-1))
                vDSP_vsubD(yPtr.baseAddress!, 1, yPtr.baseAddress! + 1, 1, &delta, 1, vDSP_Length(n-1))
            }
        }
        
        // Normalize delta by h
        vDSP_vdivD(h, 1, delta, 1, &delta, 1, vDSP_Length(n-1))
       
        // Decomposition loop
        for i in 1..<n-1 {
            let hi1 = h[i-1]
            let hi = h[i]
            let denom = hi1 + hi
            
            guard abs(denom) > 1e-12 else {
                // You could also log a warning here if needed
                y2[i] = 0
                u[i] = 0
                continue
            }

            let sig = hi1 / denom
            let p = sig * y2[i-1] + 2.0
            y2[i] = (sig - 1.0) / p

            let deltaDiff = delta[i] - delta[i-1]
            u[i] = (6.0 * deltaDiff / denom - sig * u[i-1]) / p
        }
        
        // Back substitution using Accelerate
        for k in (1..<n-1).reversed() {
            y2[k] = y2[k] * y2[k + 1] + u[k]
        }
    }
    
    private func evaluateCubicSpline(x: [T], y: [T], y2: [T], target: T) -> T {
        // Special case: if target is at the end, return last value directly
        if target >= x.last! {
            return y.last!
        }
        // Find the interval containing the target
        let k = x.lastIndex { $0 <= target } ?? 0
        let k1 = Swift.min(k + 1, x.count - 1)
        
        let h = x[k1] - x[k]
        let a = (x[k1] - target) / h
        let b = (target - x[k]) / h
        
        // Evaluate cubic spline using Accelerate
        var result: T = 0.0
        var terms = [T](repeating: 0.0, count: 4)
        
        // Compute terms with simplified expressions
        let a3 = a * a * a
        let b3 = b * b * b
        let h2 = h * h
        
        terms[0] = a * y[k]
        terms[1] = b * y[k1]
        terms[2] = (a3 - a) * y2[k] * h2 / 6.0
        terms[3] = (b3 - b) * y2[k1] * h2 / 6.0
        
        // Sum terms using Accelerate
        vDSP_sveD(terms, 1, &result, vDSP_Length(4))
        
        return result
    }
}

extension DataFrame where T == Double, I == Date {
    /// Interpolates values at the given dates using time-based interpolation
    /// - Parameters:
    ///   - dates: The target dates to interpolate values at
    ///   - method: The interpolation method to use (default: .linear)
    /// - Returns: A new DataFrame with interpolated values
    public func interpolate(dates: [I], method: InterpolationMethod = .linear) -> DataFrame {
        // Convert dates to time intervals for easier calculation
        let targetIntervals = dates.map { $0.timeIntervalSince1970 }
        let sourceIntervals = self.indexes.map { $0.timeIntervalSince1970 }
        
        // Create temporary DataFrame with Double indexes
        let tempDf = DataFrame<Double, Double, F>(
            indexes: sourceIntervals,
            values: self.values
        )
        
        // Interpolate using the Double version
        let interpolated = tempDf.interpolate(indexes: targetIntervals, method: method)
        
        // Convert back to Date indexes
        return DataFrame<Date, Double, F>(
            indexes: dates,
            values: interpolated.values
        )
    }
}

extension DataFrame where T == Double {
    /// Interpolates values at the given x values using interpolation, using a specific field as the independent variable
    /// - Parameters:
    ///   - xField: The field to use as the independent variable
    ///   - xValues: The target x values to interpolate at
    ///   - method: The interpolation method to use (default: .linear)
    /// - Returns: A new DataFrame with interpolated values
    public func interpolate(xField: F, xValues: [T], method: InterpolationMethod = .linear) -> DataFrame {
        guard !self.indexes.isEmpty else { return DataFrame(fields: self.fields) }
        guard let xFieldValues = self.values[xField] else { return DataFrame(fields: self.fields) }
        
        // Create temporary DataFrame with xField values as indexes
        let tempDf = DataFrame<Double, Double, F>(
            indexes: xFieldValues,
            values: self.values
        )
        
        // Interpolate using the standard method
        let interpolated = tempDf.interpolate(indexes: xValues, method: method)
        
        // Create result DataFrame with original index type
        return DataFrame<I, T, F>(
            indexes: self.indexes,
            values: interpolated.values
        )
    }
}
