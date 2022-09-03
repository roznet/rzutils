//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 03/09/2022.
//

import Foundation


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
    
    static let minutePerKilometer = UnitSpeed(symbol: "min/km", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*1000.0))
    static let minutePerMile = UnitSpeed(symbol: "min/mi", converter: UnitConverterInverseLinear(coefficient: 60.0/3600.0*oneMileInMeters))
}


