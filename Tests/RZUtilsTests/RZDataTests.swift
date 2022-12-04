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


}
