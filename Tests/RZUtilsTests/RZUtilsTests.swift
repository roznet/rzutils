import XCTest
@testable import RZUtils
@testable import RZUtilsSwift

final class RZUtilsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let samples : [GCNumberWithUnit] = [ GCNumberWithUnit(unit: GCUnit.kilometer(), andValue: 10.5),
                                        GCNumberWithUnit(unit: GCUnit.meter(), andValue: 2.0),
                                        GCNumberWithUnit(unit: GCUnit.bpm(), andValue: 120),
                                        GCNumberWithUnit(unit: GCUnit.minperkm(), andValue: 5.2),
                                        GCNumberWithUnit(unit: GCUnit.dimensionless(), andValue: 5),
                                        GCNumberWithUnit(unit: GCUnit.second(), andValue: 4000),
                                        ]
        let geometry = RZNumberWithUnitGeometry()
        
        for nu in samples {
            let components = nu.unit.formatComponents(for: nu.value)
            print( "\(components)")
            geometry.adjust(for: nu)
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
