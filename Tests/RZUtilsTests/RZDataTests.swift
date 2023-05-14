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
    
    func testCumSum() {
        let input : [String:[Double]] = [ "a" : [1.0,2.0,3.0,4.0],
                                          "b" : [1.0, 10.0, 100.0, 100.0] ]
        
        guard let sample = input.values.first else { XCTAssertTrue(false); return }

        let df = DataFrame<Int,Double,String>(indexes: Array(0...sample.count),
                                               values: input)
        
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
