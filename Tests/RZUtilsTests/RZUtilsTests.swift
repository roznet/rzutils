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
    
    func testUnits() {
        var one = Measurement(value: 11.0, unit: UnitSpeed.kilometersPerHour)
        let nu = GCNumberWithUnit(unit: GCUnit.kph(), andValue: 11.0)
        one.convert(to: UnitSpeed.minutePerKilometer)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        let str = formatter.string(from: one)
        print( str )

        let dateformatter = DateComponentsFormatter()
        dateformatter.allowedUnits = [.minute, .second]
        dateformatter.unitsStyle = .positional
        let nustr = nu.convert(to: GCUnit.minperkm()).formatDoubleNoUnits()
        if let v = dateformatter.string(from: (one.value * 60.0 as TimeInterval)) {
            // formatter does not add leading zero
            XCTAssertEqual(nustr,"0\(v)")
        }
        if let v = dateformatter.string(from: one.converted(to: UnitSpeed.minutePerMile).value * 60.0 as TimeInterval) {
            XCTAssertEqual(nu.convert(to: GCUnit.minpermile()).formatDoubleNoUnits(),"0\(v)")
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
