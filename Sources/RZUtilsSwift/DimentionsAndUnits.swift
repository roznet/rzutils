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
    
    static let minutePerKilometer = UnitSpeed(symbol: "min/km", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*1000.0))
    static let minutePerMile = UnitSpeed(symbol: "min/mi", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*oneMileInMeters))
    
    static let minutePerHundredMeters = UnitSpeed(symbol: "min/100 m", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*100.0))
    
    static let feetPerMinute = UnitSpeed(symbol: "fpm", converter: UnitConverterLinear(coefficient: oneFootInMeters/60.0))
    static let feetPerHour = UnitSpeed(symbol: "ft/h", converter: UnitConverterLinear(coefficient: oneFootInMeters/3600.0))
    static let meterPerHour = UnitSpeed(symbol: "m/h", converter: UnitConverterLinear(coefficient: 1.0/3600.0))

}


extension UnitAngle {
    static let semicircle = UnitAngle(symbol: "sc", converter: UnitConverterLinear(coefficient: 180.0/2147483648.0))
}

class UnitHeartRate : Dimension {
    static let beatPerMinute = UnitHeartRate(symbol: "bpm", converter: UnitConverterLinear(coefficient: 1.0))
    
    static override func baseUnit() -> Self {
        return beatPerMinute as! Self
    }
}

class UnitPercent : Dimension {
    static let percentPerHundred = UnitPercent(symbol: "%", converter: UnitConverterLinear(coefficient: 1.0/100.0))
    static let percentPerOne = UnitPercent(symbol: "%", converter: UnitConverterLinear(coefficient: 1.0))

    static override func baseUnit() -> Self {
        return percentPerOne as! Self
    }
}

@objc class UnitFuelFlow : Dimension {
    
    private static let oneGallonInLiters : Double = 3.785411784
    
    
    static let gallonPerHour = UnitFuelFlow(symbol: "gph", converter: UnitConverterLinear(coefficient: 1.0))
    static let literPerHour = UnitFuelFlow(symbol: "lph", converter: UnitConverterLinear(coefficient: 1.0/oneGallonInLiters))

    static override func baseUnit() -> Self {
        return gallonPerHour as! Self
    }
    
}

extension UnitFuelEfficiency {
    private static let oneGallonInLiters : Double = 3.785411784
    private static let oneNauticalMileInMeters : Double = 1852.0
    
    static let nauticalMilesPerGallon = UnitFuelEfficiency(symbol: "nm/gal", converter: UnitConverterInverseLinear(coefficient: oneGallonInLiters/oneNauticalMileInMeters*100.0*1000.0))
}

extension GCUnit {
    @objc func foundationUnit() -> Unit? {
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

