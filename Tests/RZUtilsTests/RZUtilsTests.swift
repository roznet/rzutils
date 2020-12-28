import XCTest
@testable import RZUtils

final class RZUtilsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let nu = GCNumberWithUnit(unit: GCUnit.meter(), andValue: 2.0)
        XCTAssertEqual(nu.value, 2.0)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
