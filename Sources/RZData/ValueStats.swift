//
//  ValueStats.swift
//  FlightLog1000
//
//  Created by Brice Rosenzweig on 07/05/2022.
//

import Foundation

public struct ValueStats {
    private func stddev(count : Int, sum : Double, ssq : Double ) -> Double?{
        let cnt = Double(count)
        guard cnt > 0 else { return nil }
        guard cnt > 1 else { return 0.0 }
        return sqrt((cnt*ssq-sum*sum)/(cnt*(cnt-1)))
    }
    
    public enum Metric : String{
        case start,end
        case min,max,average
        case total,range
    }

    public private(set) var unit : Dimension?
    
    public private(set) var start : Double
    public private(set) var end   : Double
    
    public private(set) var sum : Double
    public private(set) var sumSquare : Double
    public private(set) var weightedSum : Double
    public private(set) var max : Double
    public private(set) var min : Double
    
    public private(set) var count : Int
    public private(set) var weight : Double

    public var isValid : Bool { return self.count != 0 }
    
    public static let invalid = ValueStats(value: .nan)

    public var average : Double { return self.sum / Double(self.count) }
    public var weightedAverage : Double { return self.weightedSum / self.weight }
    public var standardDeviation : Double? { return stddev(count: self.count, sum: self.sum, ssq: self.sumSquare)}
    public var total : Double { return self.end - self.start}
    public var range : Double { return self.max - self.min }
    
    //MARK: - Create
    public init(value : Double, weight : Double = 1.0, unit : Dimension? = nil) {
        self.start = value
        self.end = value
        self.sum = value
        self.max = value
        self.min = value
        self.count = value.isFinite ? 1 : 0
        self.weight = weight
        self.weightedSum = value * weight
        self.unit = unit
        self.sumSquare = value
    }
    
    public init(start: Double, end: Double, sum: Double, sumSquare: Double, weightedSum: Double, 
                max: Double, min: Double, count: Int, weight: Double, unit: Dimension? = nil) {
        self.start = start
        self.end = end
        self.sum = sum
        self.sumSquare = sumSquare
        self.weightedSum = weightedSum
        self.max = max
        self.min = min
        self.count = count
        self.weight = weight
        self.unit = unit
    }
    
    public mutating func update(double value : Double, weight : Double = 1) {
        guard self.start.isFinite || value.isFinite else {
            self.end = Double.nan
            self.sum = Double.nan
            self.sumSquare = Double.nan
            self.max = Double.nan
            self.min = Double.nan
            self.count = value.isFinite ? self.count + 1 : 1
            self.weight = weight
            self.weightedSum = Double.nan
            return
        }
                self.end = value
                self.sum += value
                self.sumSquare += value*value
                self.max = Swift.max(self.max,value)
                self.min = Swift.min(self.min,value)
                self.count += 1
                self.weight += weight
                self.weightedSum += value * weight
    }
    
    //MARK: Metrics
    public func value(for metric: Metric) -> Double{
        switch metric {
        case .max:
            return self.max
        case .average:
            return self.average
        case .min:
            return self.min
        case .end:
            return self.end
        case .start:
            return self.start
        case .total:
            return self.total
        case .range:
            return self.range
        }
    }
    

    //MARK: - Measurements
    public var startMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: start, unit: unit) }
    public var endMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: end, unit: unit) }
    
    public var sumMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil };return Measurement(value: sum, unit: unit) }
    public var weightedSumMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: weightedSum, unit: unit) }
    public var maxMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: max, unit: unit) }
    public var minMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: min, unit: unit) }
    
    public var averageMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: average, unit: unit) }
    public var weightedAverageMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: weightedAverage, unit: unit) }
    public var totalMeasurement : Measurement<Dimension>? { guard let unit = self.unit else { return nil }; return Measurement(value: total, unit: unit) }
    
    public init(measurement: Measurement<Dimension>, weight : Double = 1) {
        self.init(value: measurement.value, weight: weight, unit: measurement.unit)
    }
    
    //MARK: - update
    public mutating func update(measurement : Measurement<Dimension>, weight : Double = 1){
        if self.unit == nil {
            self.unit = measurement.unit
        }
        let nu = measurement.converted(to: self.unit!)
        self.update(double: nu.value, weight: weight)
    }
    
    public func measurement(for metric : Metric) -> Measurement<Dimension>? {
        guard let unit = self.unit else { return nil }
        return Measurement(value: self.value(for: metric), unit: unit)
    }
}
