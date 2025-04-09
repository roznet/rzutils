//
//  RZDataTests.swift
//  
//
//  Created by Brice Rosenzweig on 03/12/2022.
//

import XCTest
import RZData

final class RZDataTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDataFrameIndexes() throws {
        let df = DataFrame<Int,Int,String>(indexes: [0,1,2,3], values: ["a":[0,1,2,3], "b":[10,11,12,13]])
        let half = df.reducedToCommonIndex(indexes: [0,2])
        XCTAssertEqual(half.indexes, [0,2])
        XCTAssertEqual(half.values["a"], [0,2])
        
        let none = df.reducedToCommonIndex(indexes: [10,20])
        XCTAssertEqual(none.count, 0)
        
        let last = df.reducedToCommonIndex(indexes: [3,4])
        XCTAssertEqual(last.indexes, [3])
        XCTAssertEqual(last.values["b"], [13])
        
        let empty = df.reducedToCommonIndex(indexes: [])
        XCTAssertEqual(empty.count, 0)
        XCTAssertTrue(empty.fields.contains("a"))
        XCTAssertTrue(empty.fields.contains("b"))

        let first = df.reducedToCommonIndex(indexes: [-2,-1,0])
        XCTAssertEqual(first.indexes, [0])
        XCTAssertEqual(first.values["b"], [10])
    }

    func testMerge() {
        let df1 = DataFrame<Int,Int,String>(indexes: [0,2,4,6],
                                           values: ["a":[10,11,12,13],
                                                    "b":[100,101,102,103]])
        let df2 = DataFrame<Int,Int,String>(indexes: [1,3,5,7],
                                           values: ["a":[20,21,22,23],
                                                    "b":[200,201,202,203],
                                                    "c":[0,0,0,0]])
        let df3 = DataFrame<Int,Int,String>(indexes: [7,8,9,10],
                                           values: ["a":[30,31,32,33],
                                                    "b":[300,301,302,303]])
        let df4 = DataFrame<Int,Int,String>(indexes: [0,1,4,5],
                                           values: ["a":[40,41,42,43],
                                                    "b":[400,401,402,403]])
        let dfe = DataFrame<Int,Int,String>()

        let m1w2 = df1.merged(with: df2)
        XCTAssertEqual(m1w2.indexes, [0,1,2,3,4,5,6,7])
        XCTAssertEqual(m1w2.values["a"], [10,20,11,21,12,22,13,23])
        XCTAssertFalse(m1w2.has(field: "c"))
        
        let m2w1 = df2.merged(with: df1)
        XCTAssertEqual(m2w1.indexes, [0,1,2,3,4,5,6,7])
        XCTAssertEqual(m2w1.values["a"], [10,20,11,21,12,22,13,23])
        XCTAssertFalse(m1w2.has(field: "c"))
        
        let m1w3 = df1.merged(with: df3)
        XCTAssertEqual(m1w3.indexes, [0,2,4,6,7,8,9,10])
        XCTAssertEqual(m1w3.values["b"], [100,101,102,103,300,301,302,303])

        let m3w1 = df3.merged(with: df1)
        XCTAssertEqual(m3w1.indexes, [0,2,4,6,7,8,9,10])
        XCTAssertEqual(m3w1.values["b"], [100,101,102,103,300,301,302,303])
        
        let m1we = df1.merged(with: dfe)
        XCTAssertEqual(m1we.indexes, df1.indexes)
        XCTAssertEqual(m1we.values["a"], df1.values["a"])

        let mew1 = dfe.merged(with: df1)
        XCTAssertEqual(mew1.indexes, df1.indexes)
        XCTAssertEqual(mew1.values["a"], df1.values["a"])

        let m1w4 = df1.merged(with: df4)
        XCTAssertEqual(m1w4.indexes, [0,1,2,4,5,6])
        XCTAssertEqual(m1w4.values["b"], [100,401,101,102,403,103])

    }

    func testExtend() {
        var df1 = DataFrame<Int,Int,String>(indexes: [0,2,4,6],
                                           values: ["a":[10,11,12,13],
                                                    "b":[100,101,102,103]])
        df1.extend(output : "c", input: "a", transform: { $0 * 2 })
        XCTAssertEqual(df1.values["c"], [20,22,24,26])

        df1.extendMultiple(output : "c", input: ["a","b"], transform: { $0[0] + $0[1] })
        XCTAssertEqual(df1.values["c"], [110,112,114,116])
    }

    func testFilter() {
        let df1 = DataFrame<Int,Int,String>(indexes: [0,2,4,6],
                                           values: ["a":[10,11,12,13],
                                                    "b":[100,101,102,103]])
        let df2 = df1.filter(input: "a") { $0 % 2 == 0 }
        XCTAssertEqual(df2.values["a"], [10,12])
        XCTAssertEqual(df2.values["b"], [100,102])
    }
    
    func testQuantiles() {
        typealias QuantileInterpolationMethod = DataFrame<Int,Double,String>.QuantileInterpolationMethod
        
        let qs : [Double] = [0.1,0.5]
        let input : [String:[Double]] = [ "a" :  [1.0,2.0,3.0,4.0], "b" : [1.0, 10.0, 100.0, 100.0] ]
        let checks : [QuantileInterpolationMethod:[String:[Double]]] = [
            .linear : [ "a" : [1.3, 2.5], "b":[3.7, 55.0]],
            .lower : [ "a" : [1.0, 2.0], "b":[1.0, 10.0]],
            .higher : [ "a" : [2.0, 3.0], "b":[10.0, 100.0]],
            .midpoint : [ "a" : [1.5, 2.5], "b":[5.5, 55.0]]
        ]
        
        guard let sample = input.values.first else { XCTAssertTrue(false); return }
        
        for (interpolation,expected) in checks {
            let df = DataFrame<Int,Double,String>(indexes: Array(0...sample.count), values: input)
            let quantiles = df.quantiles(qs, interpolation: interpolation)
            
            for (col,e) in expected {
                if let qcalculated = quantiles[col]?.values {
                    XCTAssertEqual(qcalculated, e, "checked \(col) for \(interpolation)")
                }else{
                    XCTAssertTrue(false)
                }
            }
        }
    }
    
    func buildSampleDfWithIntIndex<T>(input: [String: [T]], indexes: [Int]? = nil) -> DataFrame<Int, T, String>? {
        guard let sample = input.values.first else { XCTAssertTrue(false); return nil }
        let indexes = indexes ?? Array(0..<sample.count)
        return DataFrame<Int, T, String>(indexes: indexes, values: input)
    }
    
    func buildSampleDfWithDoubleIndex<T>(input: [String: [T]], indexes: [Double]? = nil) -> DataFrame<Double, T, String>? {
        guard let sample = input.values.first else { XCTAssertTrue(false); return nil }
        let indexes = indexes ?? Array(0..<sample.count).map { Double($0) }
        return DataFrame<Double, T, String>(indexes: indexes, values: input)
    }
    
    func testCumSum() {
        
            /*
        guard let sample = input.values.first else { XCTAssertTrue(false); return }

        let df = DataFrame<Int,Double,String>(indexes: Array(0...sample.count),
                                               values: input)
         */
        let input : [String:[Double]] = [ "a" : [1.0,2.0,3.0,4.0],
                                          "b" : [1.0, 10.0, 100.0, 100.0] ]

        if let df = self.buildSampleDfWithIntIndex(input: input){
            let cumsum = df.cumsum()
            for (col,array) in input {
                let cumulativeSum = array.reduce(into: [Double]()) { result, number in
                    if let last = result.last {
                        result.append(last + number)
                    } else {
                        result.append(number)
                    }
                }
                XCTAssertEqual(cumulativeSum, cumsum[col]?.values)
            }
        }
    }
    
    func testDescribe() {
        let valInput = [ "a" : [1.0,2.0,3.0,4.0],
                         "b" : [1.0, 10.0, 100.0, 1000.0] ]
        if let df = self.buildSampleDfWithIntIndex(input: valInput) {
            let des = df.describeValues()
            
            for (col,vals) in valInput {
                if let stats = des[col] {
                    XCTAssertEqual(stats.count,vals.count)
                    XCTAssertEqual(stats.max,vals.max())
                    XCTAssertEqual(stats.min,vals.min())
                    XCTAssertEqual(stats.sum,vals.reduce(0, +))
                }else{
                    XCTAssertTrue(false)
                }
            }
        }
        
        // Constructed such that weighted sum is equal to first element
        let weights = [16.0, 8.0, 4.0, 2.0]
        let weightInput = [ "a" : [4.0, 2.0, 6.0, 8.0],
                            "b" : [8.0, 4.0, 12.0, 16.0],
                            "w" : weights]
        if let df = self.buildSampleDfWithIntIndex(input: weightInput) {
            let des = df.describeValues(weight: "w")
            XCTAssertNil(des["w"])
            
            for (col,vals) in weightInput {
                if col == "w" {
                    continue
                }
                if let stats = des[col] {
                    XCTAssertEqual(stats.count,vals.count)
                    XCTAssertEqual(stats.max,vals.max())
                    XCTAssertEqual(stats.min,vals.min())
                    XCTAssertEqual(stats.sum,vals.reduce(0, +))
                    if let first = vals.first {
                        XCTAssertEqual(stats.weightedSum,first * weights.reduce(0,+))
                        XCTAssertEqual(stats.weightedAverage,first)
                    }
                }else{
                    XCTAssertTrue(false)
                }
            }
        }

        let catInput = [ "a" : ["a","a","b","c"],
                         "b" : ["a","b","c"] ]
        if let df = self.buildSampleDfWithIntIndex(input: catInput) {
            let des = df.describeCategorical()
            for (col,vals) in catInput {
                if let stats = des[col] {
                    XCTAssertEqual(stats.count,vals.count)
                    XCTAssertEqual(stats.start,vals.first)
                    XCTAssertEqual(stats.end,vals.last)
                }else{
                    XCTAssertTrue(false)
                }
            }
        }
    }
    
    // MARK: - Accelerate Optimized Statistics Tests
    
    func testBasicStatistics() {
        // Test basic statistical operations (sum, mean, variance, std) on a simple dataset
        let input: [String: [Double]] = [
            "a": [1.0, 2.0, 3.0, 4.0],
            "b": [10.0, 20.0, 30.0, 40.0]
        ]
        
        if let df = self.buildSampleDfWithIntIndex(input: input) {
            // Test individual field statistics
            XCTAssertEqual(df.sum(for: "a"), 10.0)
            XCTAssertEqual(df.mean(for: "a"), 2.5)
            // we are computing the sample Variance
            XCTAssertEqual(df.variance(for: "a"), 5.0/3.0)
            XCTAssertEqual(df.standardDeviation(for: "a"), sqrt(5.0/3.0))
            
            // Test all fields statistics
            let allSums = df.sums()
            XCTAssertEqual(allSums["a"], 10.0)
            XCTAssertEqual(allSums["b"], 100.0)
            
            let allMeans = df.means()
            XCTAssertEqual(allMeans["a"], 2.5)
            XCTAssertEqual(allMeans["b"], 25.0)
        }
    }
    
    func testMinMaxStatistics() {
        // Test min/max operations on various datasets
        let input: [String: [Double]] = [
            "positive": [1.0, 2.0, 3.0, 4.0],
            "negative": [-4.0, -3.0, -2.0, -1.0],
            "mixed": [-2.0, 0.0, 2.0, 4.0]
        ]
        
        if let df = self.buildSampleDfWithIntIndex(input: input) {
            // Test individual field min/max
            let positiveMinMax = df.minMax(for: "positive")
            XCTAssertEqual(positiveMinMax?.min, 1.0)
            XCTAssertEqual(positiveMinMax?.max, 4.0)
            
            // Test all fields min/max
            let allMinMax = df.minMaxes()
            XCTAssertEqual(allMinMax["negative"]?.min, -4.0)
            XCTAssertEqual(allMinMax["negative"]?.max, -1.0)
            XCTAssertEqual(allMinMax["mixed"]?.min, -2.0)
            XCTAssertEqual(allMinMax["mixed"]?.max, 4.0)
        }
    }
    
    func testMovingAverage() {
        // Test moving average calculations with different window sizes
        let input: [String: [Double]] = [
            "values": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        ]
        
        if let df = self.buildSampleDfWithIntIndex(input: input) {
            // Test individual field moving average
            let ma3 = df.movingAverage(for: "values", windowSize: 3)
            XCTAssertEqual(ma3?[2], 2.0)  // (1+2+3)/3
            XCTAssertEqual(ma3?[5], 5.0)  // (4+5+6)/3
            
            // Test all fields moving average
            let allMA = df.movingAverages(windowSize: 5)
            XCTAssertEqual(allMA["values"]?[4], 3.0)  // (1+2+3+4+5)/5
            XCTAssertEqual(allMA["values"]?[9], 8.0)  // (6+7+8+9+10)/5
        }
    }
    
    func testCorrelation() {
        // Test correlation calculations between different fields
        let input: [String: [Double]] = [
            "x": [1.0, 2.0, 3.0, 4.0, 5.0],
            "y": [2.0, 4.0, 6.0, 8.0, 10.0],  // Perfect positive correlation
            "z": [5.0, 4.0, 3.0, 2.0, 1.0]    // Perfect negative correlation
        ]
        
        if let df = self.buildSampleDfWithIntIndex(input: input) {
            // Test individual field correlations
            if let xyCorr = df.correlation(between: "x", and: "y") {
                XCTAssertEqual(xyCorr, 1.0, accuracy: 0.0001)  // Perfect positive correlation
            }
            
            if let xzCorr = df.correlation(between: "x", and: "z") {
                XCTAssertEqual(xzCorr, -1.0, accuracy: 0.0001) // Perfect negative correlation
            }
            
            // Test all fields correlations
            let allCorr = df.correlations()
            if let xyCorr = allCorr["x"]?["y"] {
                XCTAssertEqual(xyCorr, 1.0, accuracy: 0.0001)
            }
            if let xzCorr = allCorr["x"]?["z"] {
                XCTAssertEqual(xzCorr, -1.0, accuracy: 0.0001)
            }
        }
    }
    
    func testIntIndexOptimizations() {
        // Test specialized Int index optimizations
        let input: [String: [Double]] = [
            "values": [2.0, 3.0, 4.0, 5.0, 6.0]
        ]
        
        if let df = self.buildSampleDfWithIntIndex(input: input, indexes: Array(1...5)) {
            // Test binary search
            XCTAssertEqual(df.binarySearch(for: 2), 1)
            XCTAssertEqual(df.binarySearch(for: 6), nil)
            
            // Test range query
            let range = df.range(from: 1, to: 3)
            XCTAssertEqual(range?.indexes, [1, 2, 3])
            XCTAssertEqual(range?.values["values"], [2.0, 3.0, 4.0])
            
            // Test validation
            XCTAssertTrue(df.validate())
            XCTAssertTrue(df.isSorted())
        }
    }
    
    func testStatisticalEdgeCases() {
        // Test statistical functions with edge cases
        let input: [String: [Double]] = [
            "empty": [],
            "single": [42.0],
            "nan": [1.0, Double.nan, 3.0],
            "inf": [1.0, Double.infinity, 3.0]
        ]
        
        if let df = self.buildSampleDfWithIntIndex(input: input) {
            // Test empty array handling
            XCTAssertEqual(df.sum(for: "empty"), 0.0)
            let mean = df.mean(for: "empty")
            XCTAssertTrue(mean?.isNaN ?? false)
            
            // Test single value handling
            XCTAssertEqual(df.sum(for: "single"), 42.0)
            XCTAssertEqual(df.mean(for: "single"), 42.0)
            XCTAssertEqual(df.variance(for: "single"), 0.0)
            
            // Test NaN and Inf handling
            XCTAssertTrue(df.sum(for: "nan")?.isNaN ?? false)
            XCTAssertTrue(df.sum(for: "inf")?.isInfinite ?? false)
        }
    }
    
    // MARK: - Linear Regression Tests
    
    func testLinearRegression() {
        // Test perfect linear relationship
        let perfectInput: [String: [Double]] = [
            "x": [1.0, 2.0, 3.0, 4.0, 5.0],
            "y": [2.0, 4.0, 6.0, 8.0, 10.0]  // y = 2x
        ]
        
        if let df = self.buildSampleDfWithDoubleIndex(input: perfectInput) {
            let regressions = df.linearRegression(x: "x")
            
            // Test the regression function
            if let yRegression = regressions["y"] {
                // Test known points
                XCTAssertEqual(yRegression(1.0), 2.0, accuracy: 0.0001)
                XCTAssertEqual(yRegression(2.0), 4.0, accuracy: 0.0001)
                XCTAssertEqual(yRegression(3.0), 6.0, accuracy: 0.0001)
                
                // Test interpolation
                XCTAssertEqual(yRegression(1.5), 3.0, accuracy: 0.0001)
                XCTAssertEqual(yRegression(2.5), 5.0, accuracy: 0.0001)
            } else {
                XCTFail("Regression function for 'y' not found")
            }
        }
        
        // Test noisy data
        let noisyInput: [String: [Double]] = [
            "x": [1.0, 2.0, 3.0, 4.0, 5.0],
            "y": [2.1, 3.9, 6.2, 7.8, 10.1]  // Approximately y = 2x
        ]
        
        if let df = self.buildSampleDfWithDoubleIndex(input: noisyInput) {
            let regressions = df.linearRegression(x: "x")
            
            if let yRegression = regressions["y"] {
                // Test approximate values
                XCTAssertEqual(yRegression(1.0), 2.0, accuracy: 0.2)
                XCTAssertEqual(yRegression(2.0), 4.0, accuracy: 0.2)
                XCTAssertEqual(yRegression(3.0), 6.0, accuracy: 0.2)
            }
        }
    }
    
    // MARK: - Interpolation Tests
    
    func testDoubleInterpolation() {
        // Test Double index interpolation
        let doubleInput: [String: [Double]] = [
            "x": [1.0, 2.0, 3.0, 4.0],
            "y": [10.0, 20.0, 30.0, 40.0]
        ]
        
        if let df = self.buildSampleDfWithDoubleIndex(input: doubleInput) {
            // Test interpolation at known points
            let knownPoints = [1.0, 2.0, 3.0, 4.0]
            let interpolated = df.interpolate(indexes: knownPoints)
            
            XCTAssertEqual(interpolated.values["x"], [1.0, 2.0, 3.0, 4.0])
            XCTAssertEqual(interpolated.values["y"], [10.0, 20.0, 30.0, 40.0])
            
            // Test interpolation at intermediate points
            let intermediatePoints = [1.5, 2.5, 3.5]
            let interpolatedIntermediate = df.interpolate(indexes: intermediatePoints)
            
            XCTAssertEqual(interpolatedIntermediate.values["x"], [1.5, 2.5, 3.5])
            XCTAssertEqual(interpolatedIntermediate.values["y"], [15.0, 25.0, 35.0])
            
            // Test out of range interpolation
            let outOfRangePoints = [0.0, 5.0]
            let outOfRangeInterpolated = df.interpolate(indexes: outOfRangePoints)
            
            XCTAssertEqual(outOfRangeInterpolated.values["x"], [0.0, 5.0])
            XCTAssertEqual(outOfRangeInterpolated.values["y"], [10.0, 40.0])
        }
    }
    
    func testDateInterpolation() {
        // Test Date index interpolation
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dates = [
            dateFormatter.date(from: "2023-01-01 00:00:00")!,
            dateFormatter.date(from: "2023-01-02 00:00:00")!,
            dateFormatter.date(from: "2023-01-03 00:00:00")!,
            dateFormatter.date(from: "2023-01-04 00:00:00")!
        ]
        
        let dateInput: [String: [Double]] = [
            "value": [10.0, 20.0, 30.0, 40.0]
        ]
        
        let dateDf = DataFrame<Date, Double, String>(indexes: dates, values: dateInput)
        
        // Test interpolation at known dates
        let knownDates = [
            dateFormatter.date(from: "2023-01-01 00:00:00")!,
            dateFormatter.date(from: "2023-01-02 00:00:00")!,
            dateFormatter.date(from: "2023-01-03 00:00:00")!,
            dateFormatter.date(from: "2023-01-04 00:00:00")!
        ]
        
        let interpolatedDates = dateDf.interpolate(dates: knownDates)
        XCTAssertEqual(interpolatedDates.values["value"], [10.0, 20.0, 30.0, 40.0])
        
        // Test interpolation at intermediate dates
        let intermediateDates = [
            dateFormatter.date(from: "2023-01-01 12:00:00")!,
            dateFormatter.date(from: "2023-01-02 12:00:00")!,
            dateFormatter.date(from: "2023-01-03 12:00:00")!
        ]
        
        let interpolatedIntermediateDates = dateDf.interpolate(dates: intermediateDates)
        XCTAssertEqual(interpolatedIntermediateDates.values["value"], [15.0, 25.0, 35.0])
    }
    
    func testInterpolationEdgeCases() {
        // Test empty DataFrame
        let emptyDf = DataFrame<Double, Double, String>()
        let emptyInterpolated = emptyDf.interpolate(indexes: [1.0, 2.0, 3.0])
        XCTAssertEqual(emptyInterpolated.count, 0)
        
        // Test single point
        let singlePointInput: [String: [Double]] = [
            "x": [1.0],
            "y": [10.0]
        ]
        
        if let df = self.buildSampleDfWithDoubleIndex(input: singlePointInput) {
            let singleInterpolated = df.interpolate(indexes: [1.0, 1.5, 2.0])
            XCTAssertEqual(singleInterpolated.values["x"], [1.0, 1.5, 2.0])
            XCTAssertEqual(singleInterpolated.values["y"], [10.0, 10.0, 10.0])
        }
        
        // Test out of range interpolation
        let rangeInput: [String: [Double]] = [
            "x": [1.0, 2.0, 3.0],
            "y": [10.0, 20.0, 30.0]
        ]
        
        if let df = self.buildSampleDfWithDoubleIndex(input: rangeInput) {
            let outOfRangeInterpolated = df.interpolate(indexes: [0.0, 4.0])
            XCTAssertEqual(outOfRangeInterpolated.values["x"], [0.0, 4.0])
            XCTAssertEqual(outOfRangeInterpolated.values["y"], [10.0, 30.0])
        }
    }
}
