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
        private(set) var currentExtractIndex : I?
        private(set) var beforeStart : Bool = false
        private(set) var afterEnd : Bool = false
        private(set) var reachedNext : Bool = false

        init?(extractIndexes : [I],
              start : I?,
              end : I?)
        {
            guard extractIndexes.isEmpty == false else {
                return nil
            }
            self.start = start
            self.end = end
            
            // Filter out indexes before start if start is specified
            if let start = start {
                self.remainingIndexes = extractIndexes.filter { $0 >= start }
                // If all indexes are before start, return nil
                if self.remainingIndexes.isEmpty {
                    return nil
                }
            } else {
                self.remainingIndexes = extractIndexes
            }
            
            self.currentExtractIndex = start
        }
        
        mutating func next() {
            self.currentExtractIndex = self.remainingIndexes.first
            self.remainingIndexes = [I](self.remainingIndexes.dropFirst())
        }
        
        mutating func looking(at index : I){
            // if we didn't have initial extractIndex, we'll use the first index found
            if self.currentExtractIndex == nil {
                self.currentExtractIndex = index
            }
            
            self.beforeStart = self.start != nil && index < self.start!
            self.afterEnd = self.end != nil && index > self.end!
            
            if let next = self.remainingIndexes.first {
                self.reachedNext = index >= next
            }else{
                self.reachedNext = false
            }
        }
    }

    /// Extracts and aggregates data between specified indexes, creating a new DataFrame with aggregated results.
    ///
    /// This function processes the DataFrame by grouping data between consecutive indexes and applying
    /// aggregation functions to each group. It's particularly useful for time series analysis, segmenting
    /// data into meaningful intervals, and calculating running aggregates.
    ///
    /// - Parameters:
    ///   - extractIndexes: Array of indexes that define the boundaries of each group. Data will be aggregated
    ///     between consecutive indexes. The indexes must be in ascending order.
    ///   - createCollector: A closure that creates the initial aggregated value for a field. This is called
    ///     when processing the first value in a new group.
    ///   - updateCollector: A closure that updates the aggregated value with new data. This is called for
    ///     each subsequent value in the group.
    ///   - start: Optional starting index. If provided, data before this index will be ignored.
    ///   - end: Optional ending index. If provided, data after this index will be ignored.
    ///
    /// - Returns: A new DataFrame where each row corresponds to an interval between indexes, containing
    ///   the aggregated values for each field.
    ///
    /// - Throws: An error if the DataFrame operations fail.
    ///
    /// # Example
    /// ```swift
    /// // Calculate running averages between specific dates
    /// struct RunningAverage {
    ///     var sum: Double
    ///     var count: Int
    ///     
    ///     init(value: Double) {
    ///         self.sum = value
    ///         self.count = 1
    ///     }
    ///     
    ///     mutating func update(value: Double) {
    ///         sum += value
    ///         count += 1
    ///     }
    ///     
    ///     var average: Double { sum / Double(count) }
    /// }
    ///
    /// let result = try df.extract(
    ///     indexes: [date1, date2, date3],
    ///     createCollector: { _, value in RunningAverage(value: value) },
    ///     updateCollector: { collector, value in collector?.update(value: value) }
    /// )
    /// ```
    ///
    /// # Notes
    /// - The function maintains the order of the original data
    /// - Empty intervals (no data between indexes) will be skipped
    /// - The collector type `C` must be able to handle the aggregation logic for your specific use case
    /// - For statistical operations, consider using the specialized `extractValueStats` or `extractCategoricalStats` methods
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
                        if let currentExtractIndex = indexExtract.currentExtractIndex {
                            try rv.append(fieldsValues: current, for: currentExtractIndex)
                        }else{
                            throw DataFrameError.inconsistentIndexOrder
                        }
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
                    if let currentExtractIndex = indexExtract.currentExtractIndex {
                        try rv.append(fieldsValues: current, for: currentExtractIndex)
                    }else{
                        throw DataFrameError.inconsistentIndexOrder
                    }
                }catch{
                    throw error
                }
            }
        }
        return rv
    }
}

extension DataFrame where T == Double {
    public func describeValues(weights column : F? = nil, units : [F:Dimension] = [:]) -> [F:ValueStats] {
        // Use valueStats function with the entire range and specified weights
        return self.valueStats(weights: column, units: units )
    }
    
    
    /// Extracts and computes statistical values between specified indexes, creating a new DataFrame with ValueStats for each interval.
    ///
    /// This function processes the DataFrame by grouping data between consecutive indexes and calculating
    /// statistical measures (mean, variance, etc.) for each group. It's particularly useful for analyzing
    /// numerical data over time periods or other ordered intervals.
    ///
    /// - Parameters:
    ///   - extractIndexes: Array of indexes that define the boundaries of each group. Statistics will be calculated
    ///     between consecutive indexes. The indexes must be in ascending order.
    ///   - start: Optional starting index. If provided, data before this index will be ignored.
    ///   - end: Optional ending index. If provided, data after this index will be ignored.
    ///   - units: Dictionary mapping field names to their corresponding units of measurement. This is used
    ///     for proper unit handling in statistical calculations.
    ///
    /// - Returns: A new DataFrame where each row corresponds to an interval between indexes, containing
    ///   ValueStats objects for each field.
    ///
    /// - Throws: An error if the DataFrame operations fail.
    ///
    /// # Example
    /// ```swift
    /// // Calculate statistics for each day
    /// let dailyStats = try df.extractValueStats(
    ///     indexes: [date1, date2, date3],
    ///     units: ["temperature": .celsius, "pressure": .pascals]
    /// )
    /// ```
    ///
    /// # Notes
    /// - The function maintains the order of the original data
    /// - Empty intervals (no data between indexes) will be skipped
    /// - Statistics are calculated using the ValueStats type, which provides mean, variance, standard deviation,
    ///   and other statistical measures
    /// - Units are preserved in the statistical calculations
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
                        if let currentExtractIndex = indexExtract.currentExtractIndex {
                            try rv.append(fieldsValues: current, for: currentExtractIndex)
                        }else{
                            throw DataFrameError.inconsistentIndexOrder
                        }
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
                    if let currentExtractIndex = indexExtract.currentExtractIndex {
                        try rv.append(fieldsValues: current, for: currentExtractIndex)
                    }else{
                        throw DataFrameError.inconsistentIndexOrder
                    }
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

    /// Extracts and computes categorical statistics between specified indexes, creating a new DataFrame with CategoricalStats for each interval.
    ///
    /// This function processes the DataFrame by grouping data between consecutive indexes and calculating
    /// frequency distributions and other categorical statistics for each group. It's particularly useful for
    /// analyzing discrete or categorical data over time periods or other ordered intervals.
    ///
    /// - Parameters:
    ///   - extractIndexes: Array of indexes that define the boundaries of each group. Statistics will be calculated
    ///     between consecutive indexes. The indexes must be in ascending order.
    ///   - start: Optional starting index. If provided, data before this index will be ignored.
    ///   - end: Optional ending index. If provided, data after this index will be ignored.
    ///
    /// - Returns: A new DataFrame where each row corresponds to an interval between indexes, containing
    ///   CategoricalStats objects for each field.
    ///
    /// - Throws: An error if the DataFrame operations fail.
    ///
    /// # Example
    /// ```swift
    /// // Calculate categorical statistics for each day
    /// let dailyCategories = try df.extractCategoricalStats(
    ///     indexes: [date1, date2, date3]
    /// )
    /// ```
    ///
    /// # Notes
    /// - The function maintains the order of the original data
    /// - Empty intervals (no data between indexes) will be skipped
    /// - Statistics are calculated using the CategoricalStats type, which provides frequency distributions,
    ///   mode, and other categorical measures
    /// - The generic type T must conform to Hashable for categorical analysis
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
                        if let currentExtractIndex = indexExtract.currentExtractIndex {
                            try rv.append(fieldsValues: current, for: currentExtractIndex)
                        }else{
                            throw DataFrameError.inconsistentIndexOrder
                        }
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
                    if let currentExtractIndex = indexExtract.currentExtractIndex {
                        try rv.append(fieldsValues: current, for: currentExtractIndex)
                    }else{
                        throw DataFrameError.inconsistentIndexOrder
                    }
                }catch{
                    throw error
                }
            }
        }
        return rv
    }
    
}
