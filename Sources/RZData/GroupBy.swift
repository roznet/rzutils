//
//  GroupBy.swift
//  FlightLogStats
//
//  Created by Brice Rosenzweig on 19/11/2022.
//

import Foundation

extension DataFrame  {
    private struct ExtractIndexes {
        private var remainingIndexes : [I]
        
        private var start : I?
        private var end : I?
        
        // Output Variable
        private(set) var currentExtractIndex : I
        private(set) var beforeStart : Bool = false
        private(set) var afterEnd : Bool = false
        private(set) var reachedNext : Bool = false

        init?(extractIndexes : [I],
              start : I?,
              end : I?)
        {
            // require at least one extractIndex and one Index
            if let firstExtractIndex = extractIndexes.first{
                self.start = start
                self.end = end
                
                self.currentExtractIndex = firstExtractIndex
                self.remainingIndexes = [I](extractIndexes.dropFirst())
                
            }else{
                return nil
            }
        }
        
        mutating func next() {
            if let first = self.remainingIndexes.first {
                self.currentExtractIndex = first
                self.remainingIndexes = [I](self.remainingIndexes.dropFirst())
            }
        }
        
        mutating func looking(at index : I){
            self.beforeStart = self.start != nil && index < self.start!
            self.afterEnd = self.end != nil && index > self.end!
            
            if let next = self.remainingIndexes.first {
                self.reachedNext = index >= next
            }else{
                self.reachedNext = false
            }
        }
    }

    /// Will extract and compute parameters
    /// will compute statistics between date in the  array returning one stats per dates, the stats will start form the first value up to the
    /// first date in the input value, if the last date is before the end of the data, the end is skipped
    /// if a start is provided the stats starts from the first available row of data
    /// - Parameter dates: array of dates corresponding to the first date of the leg
    /// - Parameter start:first date to start statistics or nil for first date in data
    /// - Parameter end: last date (included) to collect statistics or nil for last date in data
    /// - Returns: statisitics computed between dates
    public func extract<C>(indexes extractIndexes : [I],
                    createCollector : (F,T) -> C,
                    updateCollector : (inout C?,T) -> Void,
                    start : I? = nil,
                    end : I? = nil) throws -> DataFrame<I,C,F> {
        var rv = DataFrame<I,C,F>(fields: self.fields)
        
        // we need at least one date to extract and one date of data, else we'll return empty
        // last date should be past the last date (+10 seconds) so it's included
        if var indexExtract = ExtractIndexes(extractIndexes: extractIndexes,
                                             start: start,
                                             end: end) {
            
            var current : [F:C] = [:]
            
            for (row,index) in self.indexes.enumerated() {
                indexExtract.looking(at: index)

                if indexExtract.beforeStart {
                    continue
                }
                
                if indexExtract.afterEnd {
                    break
                }
                
                if indexExtract.reachedNext {
                    do {
                        try rv.append(fieldsValues: current, for: indexExtract.currentExtractIndex)
                    }catch{
                        throw error
                    }
                    current = [:]
                    indexExtract.next()
                }
                if current.count == 0 {
                    //current = zip(self.fields,one).map { C(field: $0, value: $1) }
                    for (field,fieldValues) in self.values {
                        current[field] = createCollector(field,fieldValues[row])
                    }
                }else{
                    for (field,fieldValues) in self.values {
                        updateCollector(&current[field],fieldValues[row])
                    }
                }
            }
            // add last one if still there
            if current.count > 0 {
                do {
                    try rv.append(fieldsValues: current, for: indexExtract.currentExtractIndex)
                }catch{
                    throw error
                }
            }
        }
        return rv
    }
}

extension DataFrame where T == Double {
    public func describeValues(weight column : F? = nil, units : [F:Dimension] = [:]) -> [F:ValueStats] {
        var rv : [F:ValueStats] = [:]
        guard self.indexes.count > 0 else { return rv }
        
        var weights : [T] = []
        if let column = column, let weightValues = self.values[column] {
            weights = weightValues
        }
        
        for (col,vals) in self.values {
            if let column = column, col == column {
                // don't do stats on the weight column
                continue
            }
            var stats : ValueStats? = nil
            let hasWeights = (weights.count == vals.count)
            for (idx,val) in vals.enumerated() {
                let weight = hasWeights ? weights[idx] : 1.0
                if stats == nil {
                    stats = ValueStats(value: val, weight: weight, unit: units[col])
                }else{
                    stats?.update(double: val, weight: weight)
                }
            }
            
            rv[col] = stats
        }
        return rv
    }
    
    
    /// Will extract and compute parameters
    /// will compute statistics `ValueStats` between date in the  array returning one stats per dates,
    /// the stats will start form the first value up to the
    /// first date in the input value, if the last date is before the end of the data, the end is skipped
    /// if a start is provided the stats starts from the first available row of data
    /// - Parameter dates: array of dates corresponding to the first date of the leg
    /// - Parameter start:first date to start statistics or nil for first date in data
    /// - Parameter end: last date (included) to collect statistics or nil for last date in data
    /// - Returns: statisitics computed between dates
    public func extractValueStats(indexes extractIndexes : [I],
                 start : I? = nil,
                 end : I? = nil,
                 units : [F:Dimension] = [:]) throws -> DataFrame<I,ValueStats,F> {
        var rv = DataFrame<I,ValueStats,F>(fields: self.fields)
        
        // we need at least one date to extract and one date of data, else we'll return empty
        // last date should be past the last date (+10 seconds) so it's included
        if var indexExtract = ExtractIndexes(extractIndexes: extractIndexes,
                                             start: start,
                                             end: end) {
            
            var current : [F:ValueStats] = [:]
            
            for (row,index) in self.indexes.enumerated() {
                indexExtract.looking(at: index)
                
                if indexExtract.beforeStart {
                    continue
                }
                
                if indexExtract.afterEnd {
                    break
                }
                
                if indexExtract.reachedNext {
                    do {
                        try rv.append(fieldsValues: current, for: indexExtract.currentExtractIndex)
                    }catch{
                        throw error
                    }
                    current = [:]
                    indexExtract.next()
                }
                
                if current.count == 0 {
                    //current = zip(self.fields,one).map { C(field: $0, value: $1) }
                    for (field,fieldValues) in self.values {
                        current[field] = ValueStats(value:fieldValues[row], unit: units[field])
                    }
                }else{
                    for (field,fieldValues) in self.values {
                        current[field]?.update(double: fieldValues[row])
                    }
                }
            }
            // add last one if still there
            if current.count > 0 {
                do {
                    try rv.append(fieldsValues: current, for: indexExtract.currentExtractIndex)
                }catch{
                    throw error
                }
            }
        }
        return rv
    }
}

extension DataFrame where T : Hashable {
    
    public func describeCategorical() -> [F:CategoricalStats<T>] {
        var rv : [F:CategoricalStats<T>] = [:]
        guard self.indexes.count > 0 else { return rv }
        
        for (col,vals) in self.values {
            var stats : CategoricalStats<T>? = nil
            for val in vals {
                if stats == nil {
                    stats = CategoricalStats(value: val)
                }else{
                    stats?.update(value: val)
                }
            }
            if let stats = stats {
                rv[col] = stats
            }
        }
        return rv
    }

    /// Will extract and compute parameters
    /// will compute statistics between date in the  array returning one stats per dates, the stats will start form the first value up to the
    /// first date in the input value, if the last date is before the end of the data, the end is skipped
    /// if a start is provided the stats starts from the first available row of data
    /// - Parameter dates: array of dates corresponding to the first date of the leg
    /// - Parameter start:first date to start statistics or nil for first date in data
    /// - Parameter end: last date (included) to collect statistics or nil for last date in data
    /// - Returns: statisitics computed between dates
    public func extractCategoricalStats(indexes extractIndexes : [I],
                 start : I? = nil,
                 end : I? = nil) throws -> DataFrame<I,CategoricalStats<T>,F> {
        var rv = DataFrame<I,CategoricalStats<T>,F>(fields: self.fields)
        
        // we need at least one date to extract and one date of data, else we'll return empty
        // last date should be past the last date (+10 seconds) so it's included
        if var indexExtract = ExtractIndexes(extractIndexes: extractIndexes,
                                             start: start,
                                             end: end) {
            
            var current : [F:CategoricalStats<T>] = [:]
            
            for (row,index) in self.indexes.enumerated() {
                indexExtract.looking(at: index)
                
                if indexExtract.beforeStart {
                    continue
                }
                
                if indexExtract.afterEnd {
                    break
                }
                
                if indexExtract.reachedNext {
                    do {
                        try rv.append(fieldsValues: current, for: indexExtract.currentExtractIndex)
                    }catch{
                        throw error
                    }
                    current = [:]
                    indexExtract.next()
                }
                
                if current.count == 0 {
                    //current = zip(self.fields,one).map { C(field: $0, value: $1) }
                    for (field,fieldValues) in self.values {
                        current[field] = CategoricalStats<T>(value:fieldValues[row])
                    }
                }else{
                    for (field,fieldValues) in self.values {
                        current[field]?.update(value: fieldValues[row])
                    }
                }
            }
            // add last one if still there
            if current.count > 0 {
                do {
                    try rv.append(fieldsValues: current, for: indexExtract.currentExtractIndex)
                }catch{
                    throw error
                }
            }
        }
        return rv
    }
    
}
