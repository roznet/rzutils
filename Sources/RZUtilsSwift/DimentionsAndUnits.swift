//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 03/09/2022.
//

import Foundation
import RZUtils

class UnitConverterInverseLinear : UnitConverter {
    init(coefficient : Double, offset : Double = 0.0) {
        self.coefficient = coefficient
        self.offset = offset
    }
    
    let coefficient : Double
    let offset : Double
    
    override func baseUnitValue(fromValue value: Double) -> Double {
        return 1.0 / value * coefficient + offset
    }
    
    override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
        return 1.0 / baseUnitValue * coefficient - offset
    }
}

extension UnitSpeed {
    private static let oneMileInMeters : Double = 1609.344
    private static let oneFootInMeters : Double = 1.0/3.2808399
    
    public static let minutePerKilometer = UnitSpeed(symbol: "min/km", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*1000.0))
    public static let minutePerMile = UnitSpeed(symbol: "min/mi", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*oneMileInMeters))

    public static let secondPerKilometer = UnitSpeed(symbol: "sec/km", converter: UnitConverterInverseLinear(coefficient: 1000.0))
    public static let secondPerMile = UnitSpeed(symbol: "sec/mi", converter: UnitConverterInverseLinear(coefficient: oneMileInMeters))

    
    public static let minutePerHundredMeters = UnitSpeed(symbol: "min/100 m", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*100.0))
    
    public static let feetPerMinute = UnitSpeed(symbol: "fpm", converter: UnitConverterLinear(coefficient: oneFootInMeters/60.0))
    public static let feetPerHour = UnitSpeed(symbol: "ft/h", converter: UnitConverterLinear(coefficient: oneFootInMeters/3600.0))
    public static let meterPerHour = UnitSpeed(symbol: "m/h", converter: UnitConverterLinear(coefficient: 1.0/3600.0))

}


extension UnitAngle {
    public static let semicircle = UnitAngle(symbol: "sc", converter: UnitConverterLinear(coefficient: 180.0/2147483648.0))
}

class UnitHeartRate : Dimension {
    public static let beatPerMinute = UnitHeartRate(symbol: "bpm", converter: UnitConverterLinear(coefficient: 1.0))
    
    static override func baseUnit() -> Self {
        return beatPerMinute as! Self
    }
}

public class UnitPercent : Dimension {
    public static let percentPerHundred = UnitPercent(symbol: "%", converter: UnitConverterLinear(coefficient: 1.0/100.0))
    public static let percentPerOne = UnitPercent(symbol: "%", converter: UnitConverterLinear(coefficient: 1.0))

    public static override func baseUnit() -> Self {
        return percentPerOne as! Self
    }
}

public class UnitFuelFlow : Dimension {
    
    private static let oneGallonInLiters : Double = 3.785411784
    
    
    public static let gallonPerHour = UnitFuelFlow(symbol: "gph", converter: UnitConverterLinear(coefficient: 1.0))
    public static let literPerHour = UnitFuelFlow(symbol: "lph", converter: UnitConverterLinear(coefficient: 1.0/oneGallonInLiters))

    public static override func baseUnit() -> Self {
        return gallonPerHour as! Self
    }
    
}

public class UnitDimensionLess : Dimension {
    public static let scalar = UnitDimensionLess(symbol: "", converter: UnitConverterLinear(coefficient: 1.0))
    
    public static override func baseUnit() -> Self {
        return scalar as! Self
    }
}

extension Measurement{
    // simplify migration from GCNUmberWithUnit...
    public func formatDouble() -> String {
        let formatter = MeasurementFormatter()
        return formatter.string(from: self)
    }
}

extension UnitFuelEfficiency {
    private static let oneGallonInLiters : Double = 3.785411784
    private static let oneNauticalMileInMeters : Double = 1852.0
    
    public static let nauticalMilesPerGallon = UnitFuelEfficiency(symbol: "nm/gal", converter: UnitConverterInverseLinear(coefficient: oneGallonInLiters/oneNauticalMileInMeters*100.0*1000.0))
}

extension GCUnit {
    public var foundationUnit : Dimension? {
        switch self.key {
        // angles
        case "radian": return UnitAngle.radians
        case "dd": return UnitAngle.degrees
        case "semicircle": return UnitAngle.semicircle
            
        // pressure
        case "hPa": return UnitPressure.hectopascals
        case "inHg": return UnitPressure.inchesOfMercury
        case "psi": return UnitPressure.poundsForcePerSquareInch
        case "mmHg": return UnitPressure.millimetersOfMercury
       
        //speed
        case "mps": return UnitSpeed.metersPerSecond
        case "kph": return UnitSpeed.kilometersPerHour
        case "mph": return UnitSpeed.milesPerHour
        case "knot": return UnitSpeed.knots
        case "minperkm": return UnitSpeed.minutePerKilometer
        case "minpermile": return UnitSpeed.minutePerMile
        case "min100m": return UnitSpeed.minutePerHundredMeters
        
        case "bpm": return UnitHeartRate.beatPerMinute
            
        case "gph": return UnitFuelFlow.gallonPerHour
        case "lph" : return UnitFuelFlow.literPerHour
            
        case "milepergallon": return UnitFuelEfficiency.milesPerGallon
        case "literper100km": return UnitFuelEfficiency.litersPer100Kilometers
        case "nmpergallon": return UnitFuelEfficiency.nauticalMilesPerGallon
            
        case "liter": return UnitVolume.liters
        case "usgallon": return UnitVolume.gallons
            
        case "kilogram": return UnitMass.kilograms
        case "pound": return UnitMass.pounds
        case "gram": return UnitMass.grams
            
        case "celsius": return UnitTemperature.celsius
        case "celcius": return UnitTemperature.celsius
        case "fahrenheit": return UnitTemperature.fahrenheit
            
        case "meter": return UnitLength.meters
        case "mile": return UnitLength.miles
        case "kilometer": return UnitLength.kilometers
        case "foot": return UnitLength.feet
        case "yard": return UnitLength.yards
        case "inch": return UnitLength.inches
        case "nm": return UnitLength.nauticalMiles
        case "centimeter": return UnitLength.centimeters
        case "millimeter": return UnitLength.millimeters
        case "meterelevation": return UnitLength.meters
        case "footelevation": return UnitLength.feet
            
        case "percent": return UnitPercent.percentPerHundred
        case "percentdecimal": return UnitPercent.percentPerOne
            
        default:
            return nil
        }
    }
}

extension Unit {
    public var gcUnit : GCUnit? {
        switch self.symbol {
        case UnitAngle.radians.symbol: return GCUnit(forKey: "radian")
        case UnitAngle.degrees.symbol: return GCUnit(forKey: "dd")
        case UnitAngle.semicircle.symbol: return GCUnit(forKey: "semicircle")
            
            // pressure
        case UnitPressure.hectopascals.symbol: return GCUnit(forKey: "hPa")
        case UnitPressure.inchesOfMercury.symbol: return GCUnit(forKey: "inHg")
        case UnitPressure.poundsForcePerSquareInch.symbol: return GCUnit(forKey: "psi")
        case UnitPressure.millimetersOfMercury.symbol: return GCUnit(forKey: "mmHg")
            
            //speed
        case UnitSpeed.metersPerSecond.symbol: return GCUnit(forKey: "mps")
        case UnitSpeed.kilometersPerHour.symbol: return GCUnit(forKey: "kph")
        case UnitSpeed.milesPerHour.symbol: return GCUnit(forKey: "mph")
        case UnitSpeed.knots.symbol: return GCUnit(forKey: "knot")
        case UnitSpeed.minutePerKilometer.symbol: return GCUnit(forKey: "minperkm")
        case UnitSpeed.minutePerMile.symbol: return GCUnit(forKey: "minpermile")
        case UnitSpeed.minutePerHundredMeters.symbol: return GCUnit(forKey: "min100m")
            
        case UnitHeartRate.beatPerMinute.symbol: return GCUnit(forKey: "bpm")
            
        case UnitFuelFlow.gallonPerHour.symbol: return GCUnit(forKey: "gph")
        case UnitFuelFlow.literPerHour.symbol: return GCUnit(forKey: "lph" )
            
        case UnitFuelEfficiency.milesPerGallon.symbol: return GCUnit(forKey: "milepergallon")
        case UnitFuelEfficiency.litersPer100Kilometers.symbol: return GCUnit(forKey: "literper100km")
        case UnitFuelEfficiency.nauticalMilesPerGallon.symbol: return GCUnit(forKey: "nmpergallon")
            
        case UnitVolume.liters.symbol: return GCUnit(forKey: "liter")
        case UnitVolume.gallons.symbol: return GCUnit(forKey: "usgallon")
            
        case UnitMass.kilograms.symbol: return GCUnit(forKey: "kilogram")
        case UnitMass.pounds.symbol: return GCUnit(forKey: "pound")
        case UnitMass.grams.symbol: return GCUnit(forKey: "gram")
            
        case UnitTemperature.celsius.symbol: return GCUnit(forKey: "celsius")
        case UnitTemperature.fahrenheit.symbol: return GCUnit(forKey: "fahrenheit")
            
        case UnitLength.meters.symbol: return GCUnit(forKey: "meter")
        case UnitLength.miles.symbol: return GCUnit(forKey: "mile")
        case UnitLength.kilometers.symbol: return GCUnit(forKey: "kilometer")
        case UnitLength.feet.symbol: return GCUnit(forKey: "foot")
        case UnitLength.yards.symbol: return GCUnit(forKey: "yard")
        case UnitLength.inches.symbol: return GCUnit(forKey: "inch")
        case UnitLength.nauticalMiles.symbol: return GCUnit(forKey: "nm")
        case UnitLength.centimeters.symbol: return GCUnit(forKey: "centimeter")
        case UnitLength.millimeters.symbol: return GCUnit(forKey: "millimeter")
        case UnitLength.meters.symbol: return GCUnit(forKey: "meterelevation")
        case UnitLength.feet.symbol: return GCUnit(forKey: "footelevation")
            
        case UnitPercent.percentPerHundred.symbol: return GCUnit(forKey: "percent")
        case UnitPercent.percentPerOne.symbol: return GCUnit(forKey: "percentdecimal")
            
        default: return nil
        }
    }
}


func / (lhs : Measurement<UnitLength>, rhs : Measurement<UnitDuration>) -> Measurement<UnitSpeed> {
    let mps = lhs.converted(to: .meters).value / rhs.converted(to: .seconds).value
    return Measurement<UnitSpeed>(value: mps, unit: UnitSpeed.metersPerSecond)
}

class CompoundMeasurementFormatter<UnitType : Dimension> : MeasurementFormatter {
    enum JoinStyle {
        case simple
        case noUnits
    }
    var minimumComponents : Int = 0
    
    var joinStyle : JoinStyle = .simple
    var dimensions : [UnitType]
    var separator : String
    
    init(dimensions: [UnitType], separator: String = " ") {
        self.dimensions = dimensions
        self.separator = separator
        super.init()
        self.unitOptions = .providedUnit
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func measurements(from measurement : Measurement<UnitType>) -> [Measurement<UnitType>] {
        var zeros : [Measurement<UnitType>] = []
        var values : [Measurement<UnitType>] = []
        
        var remaining : Measurement<UnitType> = measurement
        for (idx,dim) in self.dimensions.enumerated() {
            remaining = remaining.converted(to: dim)
            var current = remaining
            if idx < (self.dimensions.count - 1) {
                current.value = floor(current.value)
            }
            // do the value substraction in the same unit (for inverse units like pace)
            remaining.value = remaining.value - current.value
            
            if current.value == 0.0 && values.count == 0{
                zeros.append(current)
            }else{
                values.append(current)
            }
        }
        if values.count < self.minimumComponents {
            values = zeros.suffix(self.minimumComponents-values.count) + values
        }
        
        return values
    }
    
    func format(from measurement: Measurement<UnitType>) -> String {
        let values = self.measurements(from: measurement)
        switch self.joinStyle {
        case .simple:
            let fmt = values.map { self.string(from: $0) }
            return fmt.joined(separator: self.separator)
        case .noUnits:
            let fmt = values.compactMap { self.numberFormatter.string(from: NSNumber(floatLiteral: $0.value)) }
            return fmt.joined(separator: self.separator)
        }
    }
    
}
