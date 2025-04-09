//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 14/05/2023.
//

import Foundation
import Accelerate

fileprivate func linearRegressionLambda(x: [Double], y: [Double]) -> ((Double) -> Double) {
    guard x.count == y.count, !x.isEmpty else {
        return { _ in 0.0 }
    }
    
    // Calculate means
    var meanX: Double = 0.0
    var meanY: Double = 0.0
    vDSP_meanvD(x, 1, &meanX, vDSP_Length(x.count))
    vDSP_meanvD(y, 1, &meanY, vDSP_Length(y.count))
    
    // Calculate covariance and variance
    var centeredX = [Double](repeating: 0.0, count: x.count)
    var centeredY = [Double](repeating: 0.0, count: y.count)
    
    // Center the data
    let meanXArray = [Double](repeating: meanX, count: x.count)
    let meanYArray = [Double](repeating: meanY, count: y.count)
    
    vDSP_vsubD(meanXArray, 1, x, 1, &centeredX, 1, vDSP_Length(x.count))
    vDSP_vsubD(meanYArray, 1, y, 1, &centeredY, 1, vDSP_Length(y.count))
    
    // Calculate covariance
    var covariance: Double = 0.0
    vDSP_dotprD(centeredX, 1, centeredY, 1, &covariance, vDSP_Length(x.count))
    
    // Calculate variance of x
    var varianceX: Double = 0.0
    vDSP_dotprD(centeredX, 1, centeredX, 1, &varianceX, vDSP_Length(x.count))
    
    // Calculate slope (b) and intercept (a)
    let b = covariance / varianceX
    let a = meanY - b * meanX
    
    // Return the linear function
    return { x in a + b * x }
}

extension DataFrame where T == Double {
    /// Calculates linear regression for the specified field against all other fields
    /// - Parameter x: The field to use as the independent variable
    /// - Returns: Dictionary of regression functions for each field
    public func linearRegression(x: F) -> [F: (T) -> T] {
        var rv: [F: (T) -> T] = [:]
        
        // Get the specified field as the independent variable (x)
        guard let xValues = self.values[x],
              !xValues.isEmpty else {
            return rv
        }
        
        // For each other field, calculate regression against the specified field
        for field in self.fields where field != x {
            if let yValues = self.values[field],
               yValues.count == xValues.count {
                rv[field] = linearRegressionLambda(x: xValues, y: yValues)
            }
        }
        
        return rv
    }
}
