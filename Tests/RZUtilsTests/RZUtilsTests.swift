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

    
    func testFoundationUnits() {
        struct ConvertTest {
            let key : String
            let convertKey : String
            let value : Double
            let eps : Double = 0.0001
        }
        let tests : [ConvertTest] = [
            ConvertTest(key: "nmpergallon", convertKey: "literper100km", value: 10.0),
            ConvertTest(key: "milepergallon", convertKey: "literper100km", value: 10.0),
            ConvertTest(key: "dd", convertKey: "semicircle", value: 90.0),
            ConvertTest(key: "minperkm", convertKey: "kph", value: 5.10),
            ConvertTest(key: "minpermile", convertKey: "mph", value: 8.20),
            ConvertTest(key: "foot", convertKey: "meter", value: 1500.0),
            ConvertTest(key: "nm", convertKey: "foot", value: 2.0),
            ConvertTest(key: "gph", convertKey: "lph", value: 15.0),
            
        ]
        for one in tests {
            let nu = GCNumberWithUnit(name: one.key, andValue: one.value)
            let converted = nu.convert(toUnitName: one.convertKey)
            if let unitFrom : Unit = nu.unit.foundationUnit(),
               let unitTo : Unit = converted.unit.foundationUnit() {
                let measure = NSMeasurement(doubleValue: one.value, unit: unitFrom)
                let measureTo = measure.converting(to: unitTo)
                
                XCTAssertNotEqual(unitTo, unitFrom)
                XCTAssertNotEqual(nu.value, converted.value, accuracy: one.eps)
                XCTAssertEqual(converted.value,measureTo.value, accuracy: one.eps)
            }
        }
    }
    static var allTests = [
        ("testExample", testExample),
    ]
}
