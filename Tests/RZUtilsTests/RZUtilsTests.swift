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
        var one = Measurement(value: 13.0, unit: UnitSpeed.kilometersPerHour)
        let nu = GCNumberWithUnit(unit: GCUnit.kph(), andValue: 13.0)
        one.convert(to: UnitSpeed.minutePerKilometer)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        let str = formatter.string(from: one)
        print( str )

        let dateformatter = DateComponentsFormatter()
        dateformatter.allowedUnits = [.minute, .second]
        dateformatter.unitsStyle = .positional
        let nupace = nu.convert(to: GCUnit.minperkm())
        let nustr = nupace.formatDoubleNoUnits()
        if let v = dateformatter.string(from: (one.value * 60.0 as TimeInterval)) {
            // can't get rounding to match
            // formatter does not add leading zero
            XCTAssertEqual(nustr,"04:37")
            XCTAssertEqual("0\(v)", "04:36")
        }
        if let v = dateformatter.string(from: one.converted(to: UnitSpeed.minutePerMile).value * 60.0 as TimeInterval) {
            // can't get rounding to match
            XCTAssertEqual(nu.convert(to: GCUnit.minpermile()).formatDoubleNoUnits(),"07:26")
            XCTAssertEqual("0\(v)","07:25")
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
            ConvertTest(key: "min100m", convertKey: "mps", value: 10.0),
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
            if let unitFrom : Unit = nu.unit.foundationUnit,
               let unitTo : Unit = converted.unit.foundationUnit {
                let measure = NSMeasurement(doubleValue: one.value, unit: unitFrom)
                let measureTo = measure.converting(to: unitTo)
                
                XCTAssertNotEqual(unitTo, unitFrom)
                XCTAssertNotEqual(nu.value, converted.value, accuracy: one.eps)
                XCTAssertEqual(converted.value,measureTo.value, accuracy: one.eps)
            }
        }
    }
    
    func testProduct() {
        let dist = Measurement<UnitLength>(value: 1.0, unit: UnitLength.kilometers)
        let dur  = Measurement<UnitDuration>(value: 5.2, unit: UnitDuration.minutes)
        let speed = Measurement<UnitSpeed>(value: 13.0, unit: UnitSpeed.kilometersPerHour)
        let speed2  = dist / dur
        
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2
        XCTAssertEqual(formatter.string(from: speed2.converted(to: UnitSpeed.kilometersPerHour).measurementDimension),
                       "11.54 km/h")
        
        let dformatter = CompoundMeasurementFormatter(dimensions: [UnitDuration.hours,UnitDuration.minutes,UnitDuration.seconds], separator: " ")
        dformatter.unitStyle = .short
        let k = dformatter.format(from: dur)
        XCTAssertEqual(k, "5m 12s")
        
        dformatter.separator = ":"
        dformatter.joinStyle = .noUnits
        dformatter.numberFormatter.minimumIntegerDigits = 2
        
        let k2 = dformatter.format(from: dur)
        XCTAssertEqual(k2, "05:12")
        
        dformatter.minimumComponents = 3
        let k3 = dformatter.format(from: dur)
        XCTAssertEqual(k3, "00:05:12")
        
        let height = Measurement(value: 187, unit: UnitLength.centimeters)
        let fiformatter = CompoundMeasurementFormatter(dimensions: [UnitLength.feet,UnitLength.inches])
        let k4 = fiformatter.format(from: height)
        XCTAssertEqual(k4, "6 ft 1.622 in")
        
        let paceformatter = CompoundMeasurementFormatter(dimensions: [UnitSpeed.minutePerKilometer, UnitSpeed.secondPerKilometer])
        let k5 = paceformatter.format(from: speed)
        XCTAssertEqual(k5, "4 min/km 36.923 sec/km")
        paceformatter.joinStyle = .noUnits
        paceformatter.numberFormatter.minimumIntegerDigits = 2
        paceformatter.minimumComponents = 2
        paceformatter.separator = ":"
        paceformatter.numberFormatter.maximumFractionDigits = 0
        let k6 = paceformatter.format(from: speed)
        XCTAssertEqual(k6, "04:37")
    }
    
    func testGradient() throws {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2
        
        let grP = Measurement(value: 5.0, unit: UnitClimbGradient.percent)
        let grA = Measurement(value: 3.0, unit: UnitClimbGradient.degrees)
                
        XCTAssertEqual( formatter.string(for: grP.converted(to: UnitClimbGradient.degrees)), "2.86 °")
        XCTAssertEqual( formatter.string(for: grA.converted(to: UnitClimbGradient.percent)), "5.24 %")
        
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
