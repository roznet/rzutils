//
//  CategoricalStats.swift
//  FlightLogStats
//
//  Created by Brice Rosenzweig on 24/11/2022.
//

import Foundation

public struct CategoricalStats<CategoricalValue : Hashable>{
    public enum Metric : String {
        case start
        case end
        case mostFrequent
    }
    
    private var valuesCount : [CategoricalValue:Int]
    public private(set) var start : CategoricalValue
    public private(set) var end : CategoricalValue
    public private(set) var mostFrequent : CategoricalValue
    
    public init(value: CategoricalValue){
        self.start = value
        self.end = value
        self.mostFrequent = value
        self.valuesCount = [value:1]
    }
    
    public mutating func update(value: CategoricalValue) {
        self.end = value
        self.valuesCount[value, default: 0] += 1
        if self.valuesCount[self.mostFrequent, default: 0] < self.valuesCount[value, default: 0] {
            self.mostFrequent = value
        }
    }

    public func value(for metric: Metric) -> CategoricalValue {
        switch metric {
        case .end:
            return self.end
        case .start:
            return self.start
        case .mostFrequent:
            return self.mostFrequent
        }
    }
    
}
