//
//  TimedDataByField.swift
//  FlightLog1000
//
//  Created by Brice Rosenzweig on 24/04/2022.
//

import Foundation
import CoreLocation
import Accelerate

/// A DataFrame is a two-dimensional, size-mutable, potentially heterogeneous tabular data structure.
/// It provides a flexible and efficient way to store and manipulate data with labeled columns and rows.
///
/// The DataFrame is generic over three types:
/// - `I`: The index type (must be Comparable & Hashable)
/// - `T`: The value type
/// - `F`: The field/column name type (must be Hashable)
///
/// Example usage:
/// ```swift
/// // Create a DataFrame with Double values and String field names
/// var df = DataFrame<Int, Double, String>()
/// 
/// // Add data
/// try df.append(field: "temperature", element: 25.5, for: 1)
/// try df.append(field: "humidity", element: 60.0, for: 1)
/// 
/// // Access data
/// if let tempColumn = df["temperature"] {
///     print(tempColumn.values) // [25.5]
/// }
/// ```
public struct DataFrame<I: Comparable & Hashable, T, F: Hashable>: Sequence {
    public typealias Element = (index: I, row: [F:T])
    
    //MARK: - Type definitions
    
    /// Errors that can occur during DataFrame operations
    public enum DataFrameError : Error {
        /// Thrown when attempting to append data with an index that would break the sorted order
        case inconsistentIndexOrder
        /// Thrown when the number of values doesn't match the number of indexes
        case inconsistentDataSize
        /// Thrown when attempting to access a field that doesn't exist
        case unknownField(F)
    }
    
    /// Represents a single row of data in the DataFrame
    public typealias Row = [F:T]
    
    /// Represents a single data point with its index and value
    public struct Point {
        /// The index of the data point
        public let index : I
        /// The value of the data point
        public let value : T
    }
    /// A Column represents a single column of data in a DataFrame, consisting of an ordered collection of values
    /// and their corresponding indexes.
    ///
    /// A Column is a fundamental building block of a DataFrame, providing a way to access and manipulate
    /// data in a single field. It maintains the relationship between values and their indexes, ensuring
    /// that the data remains properly aligned.
    ///
    /// Example usage:
    /// ```swift
    /// // Create a column with temperature readings
    /// let indexes = [1, 2, 3]
    /// let values = [25.5, 26.0, 24.8]
    /// let tempColumn = Column(indexes: indexes, values: values)
    ///
    /// // Access the first reading
    /// if let firstReading = tempColumn.first {
    ///     print("First temperature: \(firstReading.value) at index \(firstReading.index)")
    /// }
    /// ```
    ///
    /// - Note: The number of indexes must match the number of values in the column.
    /// - Note: The indexes should be sorted in ascending order for optimal performance.
    public struct Column {
        /// The indexes corresponding to each value in the column
        public let indexes : [I]
        /// The values in the column
        public let values : [T]
        
        /// Returns the first point in the column, if any
        public var first : Point? { 
            guard let i = indexes.first, let v = values.first else { return nil }
            return Point(index: i, value: v) 
        }
        
        /// Returns the last point in the column, if any
        public var last : Point? { 
            guard let i = indexes.last, let v = values.last else { return nil }
            return Point(index: i, value: v) 
        }
        
        /// The number of elements in the column
        public var count : Int { return indexes.count }
        
        /// Returns a new column with the first k elements removed
        public func dropFirst(_ k : Int) -> Column {
            return Column(indexes: [I](self.indexes.dropFirst(k)), 
                         values: [T](self.values.dropFirst(k)))
        }
        
        /// Creates a new column with the given indexes and values
        public init(indexes: [I], values: [T]) {
            self.indexes = indexes
            self.values = values
        }
        
        /// Accesses the value at the specified index
        public subscript(_ idx : Int) -> T? {
            return self.values.indices.contains(idx) ? self.values[idx] : nil
        }
    }
    
    //MARK: - Stored properties
    
    /// The indexes (row labels) of the DataFrame
    public private(set) var indexes : [I]
    
    /// The values stored in the DataFrame, organized by field name
    public private(set) var values : [F:[T]]
    
    //MARK: - Computed properties
    
    /// Returns an array of all field names in the DataFrame
    public var fields : [F] { return Array(values.keys) }
    
    /// Returns the number of rows in the DataFrame
    public var count : Int { return indexes.count }
    
    //MARK: - Initialization
    
    /// Creates an empty DataFrame with the specified fields
    /// - Parameter fields: The field names to initialize
    public init(fields : [F]){
        indexes = []
        values = [:]
        for field in fields {
            values[field] = []
        }
    }
    
    /// Creates a DataFrame with the given indexes and values
    /// - Parameters:
    ///   - indexes: The row indexes
    ///   - values: The values organized by field name
    public init(indexes : [I], values: [F:[T]]){
        self.indexes = indexes
        self.values = values
    }
    
    /// Creates an empty DataFrame
    public init() {
        indexes = []
        values = [:]
    }
    
    /// Creates a DataFrame from arrays of indexes, fields, and rows
    /// - Parameters:
    ///   - indexes: The row indexes
    ///   - fields: The field names
    ///   - rows: The data rows, where each row is an array of values
    /// - Note: The number of values in each row must match the number of fields
    public init(indexes : [I], fields : [F], rows : [[T]]){
        self.indexes = []
        self.values = [:]
        
        guard indexes.first != nil else {
            return
        }
        
        var lastindex = indexes.first!
        
        self.indexes.reserveCapacity(indexes.capacity)
        
        for field in fields {
            self.values[field] = []
            self.values[field]?.reserveCapacity(indexes.capacity)
        }
        
        for (index,row) in zip(indexes,rows) {
            if index < lastindex {
                self.indexes.removeAll(keepingCapacity: true)
                for field in fields {
                    self.values[field]?.removeAll(keepingCapacity: true)
                }
            }
            // edge case date is repeated
            if self.indexes.count == 0 || index != lastindex {
                self.indexes.append(index)
                for (field,element) in zip(fields,row) {
                    self.values[field]?.append(element)
                }
                lastindex = index
            }
        }
    }
    /// Creates a DataFrame from arrays of indexes and values
    /// - Parameters:
    ///   - indexes: The row indexes
    ///   - values: A dictionary mapping field names to arrays of values
    ///   - fields: Optional field names to include in the DataFrame. If nil, all fields from values will be used
    /// - Throws: `DataFrameError.unknownField` if any of the specified fields don't exist in the values dictionary
    /// - Note: The number of values in each field's array must match the number of indexes
    /// - Note: The indexes must be in ascending order
    private init(indexes : [I], values: [F:[T]], fields: [F]? = nil) throws{
        var v : [F:[T]] = [:]
        let fieldsToUse : [F] = fields ?? Array(values.keys)
        
        for field in fieldsToUse {
            if let c = values[field] {
                v[field] = c
            }else{
                throw DataFrameError.unknownField(field)
            }
        }
        self.indexes = indexes
        self.values = v
    }
    
    //MARK: - Private Helpers
    
    /// Checks if the new index maintains the sorted order and updates the indexes array
    /// - Parameter index: The new index to check and potentially add
    /// - Throws: `DataFrameError.inconsistentIndexOrder` if the index would break the sorted order
    private mutating func indexCheckAndUpdate(index : I) throws {
        if let last = indexes.last {
            if index > last {
                indexes.append(index)
            } else if index < last {
                throw DataFrameError.inconsistentIndexOrder
            }
        } else {
            // nothing yet, insert date
            indexes.append(index)
        }
    }
    
    /// Updates a field with a new value and checks for consistency
    /// - Parameters:
    ///   - field: The field to update
    ///   - element: The value to append
    /// - Throws: `DataFrameError.inconsistentDataSize` if the number of values becomes inconsistent
    private mutating func updateField(field : F, element : T) throws {
        values[field, default: []].append(element)
        
        if values[field, default: []].count != indexes.count {
            throw DataFrameError.inconsistentDataSize
        }
    }
    
    //MARK: - Data Manipulation
    
    /// Reserves enough space to store the specified number of elements
    /// - Parameter capacity: The number of elements to reserve space for
    mutating public func reserveCapacity(_ capacity : Int){
        indexes.reserveCapacity(capacity)
        for k in values.keys {
            values[k]?.reserveCapacity(capacity)
        }
    }
    
    /// Clears all data from the DataFrame
    /// - Parameter fields: Optional list of fields to keep (empty by default)
    mutating public func clear(fields : [F] = []) {
        indexes = []
        values = [:]
        for field in fields {
            values[field] = []
        }
    }
    
    /// Appends a single value to a field at the specified index
    /// - Parameters:
    ///   - field: The field to append to
    ///   - element: The value to append
    ///   - index: The index for the new value
    /// - Throws: `DataFrameError.inconsistentIndexOrder` if the index would break the sorted order
    /// - Throws: `DataFrameError.inconsistentDataSize` if the number of values becomes inconsistent
    public mutating func append(field : F, element : T, for index : I) throws {
        try self.indexCheckAndUpdate(index: index)
        try self.updateField(field: field, element: element)
    }
    
    /// Appends a single value to a field at the specified index without consistency checks
    /// - Parameters:
    ///   - field: The field to append to
    ///   - element: The value to append
    ///   - index: The index for the new value
    /// - Note: This is faster than `append` but assumes the caller maintains consistency
    public mutating func unsafeFastAppend(field : F, element : T, for index : I) throws {
        if indexes.last == nil || indexes.last! != index {
            self.indexes.append(index)
        }
        values[field, default: []].append(element)
    }
    
    /// Appends multiple field-value pairs at the specified index
    /// - Parameters:
    ///   - fieldsValues: Dictionary of field-value pairs to append
    ///   - index: The index for the new values
    /// - Throws: `DataFrameError.inconsistentIndexOrder` if the index would break the sorted order
    /// - Throws: `DataFrameError.inconsistentDataSize` if the number of values becomes inconsistent
    public mutating func append(fieldsValues : [F:T], for index : I) throws {
        try self.indexCheckAndUpdate(index: index)
        for (field,value) in fieldsValues {
            try self.updateField(field: field, element: value)
        }
    }
    
    /// Appends multiple values to multiple fields at the specified index without consistency checks
    /// - Parameters:
    ///   - fields: The fields to append to
    ///   - elements: The values to append
    ///   - index: The index for the new values
    /// - Note: This is faster than `append` but assumes the caller maintains consistency
    public mutating func unsafeFastAppend(fields : [F], elements : [T], for index : I) {
        self.indexes.append(index)
        for (field,element) in zip(fields,elements) {
            self.values[field, default: []].append(element)
        }
    }
    
    /// Appends multiple values to multiple fields at the specified index
    /// - Parameters:
    ///   - fields: The fields to append to
    ///   - elements: The values to append
    ///   - index: The index for the new values
    /// - Throws: `DataFrameError.inconsistentIndexOrder` if the index would break the sorted order
    /// - Throws: `DataFrameError.inconsistentDataSize` if the number of values becomes inconsistent
    public mutating func append(fields : [F], elements: [T], for index : I) throws {
        try self.indexCheckAndUpdate(index: index)
        for (field,element) in zip(fields,elements) {
            try self.updateField(field: field, element: element)
        }
    }
    
    /// Returns a new DataFrame with all data before the specified index removed
    /// - Parameter index: The index to drop before
    /// - Returns: A new DataFrame with data from the specified index onwards, or nil if the index is not found
    public func dropFirst(index : I) -> DataFrame? {
        guard let found = self.indexes.firstIndex(of: index) else { return nil }
        
        var rv = DataFrame(fields: [F](self.values.keys))
        rv.indexes = [I](self.indexes.dropFirst(found))
        for (field,values) in self.values {
            rv.values[field] = [T](values.dropFirst(found))
        }
        return rv
    }
    
    /// Returns a new DataFrame with data removed until a condition is met
    /// - Parameters:
    ///   - field: The field to check for the condition
    ///   - minimumMatchCount: The minimum number of consecutive matches required
    ///   - matching: The condition to check
    /// - Returns: A new DataFrame with data from the first match onwards, or nil if no match is found
    public func dropFirst(field : F, minimumMatchCount : Int = 1, matching : ((T) -> Bool)) -> DataFrame? {
        guard let fieldValues = self.values[field] else { return nil }
        
        var rv = DataFrame(fields: [F](self.values.keys))
        var found : Int = -1
        var matchCount : Int = 0
        
        for (idx,value) in fieldValues.enumerated() {
            if matching(value) {
                matchCount += 1
            } else {
                matchCount = 0
            }
            
            if matchCount >= minimumMatchCount {
                found = idx
                break
            }
        }
        
        if found != -1 {
            rv.indexes = [I](self.indexes.dropFirst(found))
            for (oneField,oneFieldValues) in self.values {
                rv.values[oneField] = [T](oneFieldValues.dropFirst(found))
            }
        }
        return rv
    }
    
    /// Returns a new DataFrame with data removed from the end until a condition is met
    /// - Parameters:
    ///   - field: The field to check for the condition
    ///   - matching: The condition to check
    /// - Returns: A new DataFrame with data up to the last match
    public func dropLast(field : F, matching : ((T) -> Bool)) -> DataFrame? {
        guard let fieldValues = self.values[field] else { return nil }
        
        var rv = DataFrame(fields: Array(self.values.keys))
        var found : Int = 0
        
        for (idx,value) in fieldValues.reversed().enumerated() {
            if matching(value) {
                found = idx
                break
            }
        }
        
        rv.indexes = [I](self.indexes.dropLast(found))
        for (oneField,oneFieldValues) in self.values {
            rv.values[oneField] = [T](oneFieldValues.dropLast(found))
        }
        return rv
    }
    
    /// Adds a new column to the DataFrame
    /// - Parameters:
    ///   - field: The name of the new field
    ///   - column: The column data to add
    /// - Note: The column's indexes must match the DataFrame's indexes
    public mutating func add(field : F, column : Column) {
        if indexes == column.indexes {
            self.values[field] = column.values
        }
    }
    
    //MARK: - Merge
    
    /// Merges another DataFrame into this one
    /// - Parameter other: The DataFrame to merge with
    /// - Note: If indexes are not the same, the result will have the union of indexes
    /// - Note: If indexes are the same, values from this DataFrame take precedence
    mutating public func merge(with other : DataFrame){
        let merged = self.merged(with: other)
        self.indexes = merged.indexes
        self.values = merged.values
    }

    /// Returns a new DataFrame that is the result of merging this DataFrame with another
    /// - Parameter other: The DataFrame to merge with
    /// - Returns: A new DataFrame containing the merged data
    /// - Note: If indexes are not the same, the result will have the union of indexes
    /// - Note: If indexes are the same, values from this DataFrame take precedence
    public func merged(with other : DataFrame) -> DataFrame{
        // handle simple cases
        guard self.indexes.first != nil else { return other }
        guard other.indexes.first != nil else { return self }
        
        var thisBound = (lower : 0, upper: 0)
        var otherBound = (lower : 0, upper : 0)
        
        var thisIndex = (lower: self.indexes.first!, upper: self.indexes.first!)
        var otherIndex = (lower: other.indexes.first!, upper: other.indexes.first!)
        
        var mergedIndex : [I] = []
        var mergedValues : [F:[T]] = [:]
        let fields = Set(self.fields).intersection(other.fields)
        
        for field in fields {
            mergedValues[field] = []
        }
        
        while thisBound.upper < self.indexes.count || otherBound.upper < other.indexes.count {
            // we handle == case for index such that it picks up self...
            while (thisIndex.upper <= otherIndex.lower || otherBound.upper == other.indexes.count) && thisBound.upper < self.indexes.count {
                // if equal, move other as well as we will pick up value from self
                if thisIndex.upper == otherIndex.lower {
                    otherBound.lower += 1
                    otherBound.upper = otherBound.lower
                    if otherBound.lower < other.indexes.count {
                        otherIndex.lower = other.indexes[otherBound.lower]
                        otherIndex.upper = otherIndex.lower
                    }
                }
                thisBound.upper += 1
                if thisBound.upper < self.indexes.count {
                    thisIndex.upper = self.indexes[thisBound.upper]
                }
            }
            if thisBound.lower < thisBound.upper {
                mergedIndex.append(contentsOf: self.indexes[thisBound.lower..<thisBound.upper])
                for field in fields {
                    if let slice = self.values[field]?[thisBound.lower..<thisBound.upper] {
                        mergedValues[field]?.append(contentsOf: slice)
                    }
                }
                thisBound.lower = thisBound.upper
                thisIndex.lower = thisIndex.upper
            }
            while (otherIndex.upper < thisIndex.lower || thisBound.upper == self.indexes.count) && otherBound.upper < other.indexes.count {
                otherBound.upper += 1
                if otherBound.upper < other.indexes.count {
                    otherIndex.upper = other.indexes[otherBound.upper]
                }
            }
            if otherBound.lower < otherBound.upper {
                mergedIndex.append(contentsOf: other.indexes[otherBound.lower..<otherBound.upper])
                for field in fields {
                    if let slice = other.values[field]?[otherBound.lower..<otherBound.upper] {
                        mergedValues[field]?.append(contentsOf: slice)
                    }
                }
                otherBound.lower = otherBound.upper
                otherIndex.lower = otherIndex.upper
            }
        }
        return DataFrame(indexes: mergedIndex, values: mergedValues)
    }
    
    //MARK: - Transform
    
    /// Returns a new DataFrame containing only the data between the specified indexes
    /// - Parameters:
    ///   - start: The start index (inclusive). If nil, starts from the beginning
    ///   - end: The end index (exclusive). If nil, goes to the end
    /// - Returns: A new DataFrame with the sliced data
    public func sliced(start : I? = nil, end : I? = nil) -> DataFrame {
        guard self.indexes.count > 0 && (start != nil || end != nil) else { return self }
        
        var indexStart : Int = 0
        var indexEnd : Int = self.indexes.count
        
        if let start = start {
            indexStart = self.indexes.firstIndex { $0 >= start } ?? 0
        }
        if let end = end {
            if let found = self.indexes.lastIndex(where: { $0 < end }) {
                indexEnd = self.indexes.index(after: found)
            }
        }
        var rv = DataFrame(fields: self.fields)
        rv.indexes = [I](self.indexes[indexStart..<indexEnd])
        for (field,value) in self.values {
            rv.values[field] = [T](value[indexStart..<indexEnd])
        }
        return rv
    }
    
    /// Returns a new DataFrame containing only the specified fields
    /// - Parameter fields: The fields to include in the new DataFrame
    /// - Returns: A new DataFrame with only the specified fields
    /// - Throws: `DataFrameError.unknownField` if any of the specified fields don't exist
    public func dataFrame(for fields : [F]) throws -> DataFrame {
        return try DataFrame(indexes: self.indexes, values: self.values, fields: fields)
    }

    /// Creates a new column by transforming values from an existing column
    /// - Parameters:
    ///   - output: The name of the new field
    ///   - input: The name of the input field
    ///   - transform: The transformation function to apply
    mutating public func extend(output : F, input : F, transform : (T) -> T) {
        guard let inputValues = self.values[input] else { return }
        var outputValues : [T] = []
        outputValues.append(contentsOf: inputValues.map(transform))
        self.values[output] = outputValues
    }

    /// Creates a new column by transforming values from multiple existing columns
    /// - Parameters:
    ///   - output: The name of the new field
    ///   - input: The names of the input fields
    ///   - transform: The transformation function to apply
    mutating public func extendMultiple(output : F, input : [F], transform : ([T]) -> T) {
        var outputValues : [T] = []
        for index in self.indexes.indices {
            var inputValues : [T] = []
            for field in input {
                if let value = self.values[field]?[index] {
                    inputValues.append(value)
                }
            }
            outputValues.append(transform(inputValues))
        }
        self.values[output] = outputValues
    }

    //MARK: - Filter

    /// Returns a new DataFrame containing only rows that satisfy the given condition
    /// - Parameters:
    ///   - input: The field to check for the condition
    ///   - filter: The condition to check
    /// - Returns: A new DataFrame with only the rows that satisfy the condition
    public func filter(input : F, filter : (T) -> Bool) -> DataFrame {
        guard let inputValues = self.values[input] else { return self }
        let indexes = inputValues.enumerated().filter { filter($0.element) }.map { $0.offset }
        var rv = DataFrame(fields: self.fields)
        for index in indexes {
            rv.indexes.append(self.indexes[index])
            for (field,value) in self.values {
                rv.values[field]?.append(value[index])
            }
        }
        return rv
    }
    
    //MARK: - Access
    
    /// Checks if the DataFrame contains all the specified fields
    /// - Parameter fields: The fields to check for
    /// - Returns: true if all fields exist, false otherwise
    public func has(fields : [F]) -> Bool {
        let queryFieldSet = Set(fields)
        let thisFieldSet = Set(self.fields)
        return queryFieldSet.isSubset(of: thisFieldSet)
    }
    
    /// Checks if the DataFrame contains the specified field
    /// - Parameter field: The field to check for
    /// - Returns: true if the field exists, false otherwise
    public func has(field : F) -> Bool {
        return self.values[field] != nil
    }
    
    /// Returns the last point in the specified field that satisfies the given condition
    /// - Parameters:
    ///   - field: The field to search in
    ///   - matching: Optional condition to check. If nil, returns the last point regardless of value
    /// - Returns: The last matching point, or nil if no match is found
    public func last(field : F, matching : ((T) -> Bool)? = nil) -> Point?{
        guard let fieldValues = self.values[field],
              let lastDate = self.indexes.last,
              let lastValue = fieldValues.last
        else {
            return nil
        }
        
        if let matching = matching {
            for (date,value) in zip(indexes.reversed(),fieldValues.reversed()) {
                if matching(value) {
                    return Point(index: date, value: value)
                }
            }
            return nil
        } else {
            return Point(index: lastDate, value: lastValue)
        }
    }

    /// Returns the first point in the specified field that satisfies the given condition
    /// - Parameters:
    ///   - field: The field to search in
    ///   - matching: Optional condition to check. If nil, returns the first point regardless of value
    /// - Returns: The first matching point, or nil if no match is found
    public func first(field : F, matching : ((T) -> Bool)? = nil) -> Point?{
        guard let fieldValues = self.values[field],
              let firstDate = self.indexes.first,
              let firstValue = fieldValues.first
        else {
            return nil
        }
        
        if let matching = matching {
            for (date,value) in zip(indexes,fieldValues) {
                if matching(value) {
                    return Point(index: date, value: value)
                }
            }
            return nil
        } else {
            return Point(index: firstDate, value: firstValue)
        }
    }
    
    /// Returns the point at the specified index in the given field
    /// - Parameters:
    ///   - field: The field to get the point from
    ///   - index: The index of the point
    /// - Returns: The point at the specified index, or nil if the index is out of bounds
    public func point(for field : F, at index : Int) -> Point? {
        guard let fieldValues = self.values[field], index < self.indexes.count else { return nil }
        let value = fieldValues[index]
        let date = self.indexes[index]
        return Point(index: date, value: value)
    }

    /// Returns the value at the specified index in the given field
    /// - Parameters:
    ///   - field: The field to get the value from
    ///   - index: The index of the value
    /// - Returns: The value at the specified index, or nil if the index is out of bounds
    public func value(for field : F, at index : Int) -> T? {
        guard let fieldValues = self.values[field], index < self.indexes.count else { return nil }
        let value = fieldValues[index]
        return value
    }
    
    /// Returns a row of data at the specified index
    /// - Parameter index: The index of the row
    /// - Returns: A dictionary mapping field names to values for the specified row
    public func row(at index : Int) -> Row {
        var rv : Row = [:]
        for (field,values) in self.values {
            if let value = values[safe: index] {
                rv[field] = value
            }
        }
        return rv
    }
    
    /// Returns the column for the specified field
    /// - Parameter field: The field to get the column for
    /// - Returns: The column containing the field's data, or nil if the field doesn't exist
    public func column(for field : F) -> Column? {
        guard let values = self.values[field] else { return nil }
        return Column(indexes: self.indexes, values: values)
    }
    
    /// Subscript access to columns by field name
    /// - Parameter field: The field to get the column for
    /// - Returns: The column containing the field's data, or nil if the field doesn't exist
    public subscript(_ field : F) -> Column? {
        return self.column(for: field)
    }
    
    //MARK: - Sequence Conformance

    public func makeIterator() -> AnyIterator<Element> {
        var currentIndex = 0
        let indexes = self.indexes
        let fields = self.fields
        let values = self.values
        
        return AnyIterator {
            guard currentIndex < indexes.count else { return nil }
            let index = indexes[currentIndex]
            var row: [F:T] = [:]
            for field in fields {
                row[field] = values[field]?[currentIndex]
            }
            currentIndex += 1
            return (index, row)
        }
    }
}

extension DataFrame.Column : Sequence {
    /// Iterator for Column that yields Point values
    public struct ColumnIterator : IteratorProtocol {
        let column : DataFrame.Column
        var idx : Int
        
        public init(_ column : DataFrame.Column) {
            self.column = column
            idx = 0
        }
        
        public mutating func next() -> DataFrame.Point? {
            guard idx < column.indexes.count else { return nil }
            let rv = DataFrame.Point(index: column.indexes[idx], value: column.values[idx])
            idx += 1
            return rv
        }
    }
    
    /// Returns an iterator over the Column's Point values
    public func makeIterator() -> ColumnIterator {
        return ColumnIterator(self)
    }
}

extension DataFrame.Column where T : Hashable {
    /// Returns an array of unique values in the column
    public var uniqueValues : [T] { return Array(Set(self.values)) }
}

//MARK: - Coordinate specialisation
extension DataFrame where T == CLLocationCoordinate2D {
    public func boundingPoints(field : F) -> (northEast : CLLocationCoordinate2D, southWest : CLLocationCoordinate2D)? {
        guard let column = self.values[field] else { return nil }
        
        var northEastPoint : CLLocationCoordinate2D? = nil
        var southWestPoint : CLLocationCoordinate2D? = nil
        
        for coord in column {
            if coord.longitude <= -180.0 {
                continue
            }

            if let east = northEastPoint, let west = southWestPoint {
                if coord.latitude > east.latitude {
                    northEastPoint?.latitude = coord.latitude
                }
                if coord.longitude > east.longitude {
                    northEastPoint?.longitude = coord.longitude
                }
                if coord.latitude < west.latitude {
                    southWestPoint?.latitude = coord.latitude
                }
                if coord.longitude < west.longitude{
                    southWestPoint?.longitude = coord.longitude
                }
            }else{
                northEastPoint = coord
                southWestPoint = coord
            }
        }
        if let ne = northEastPoint, let sw = southWestPoint {
            return (northEast: ne, southWest: sw)
        }else{
            return nil
        }
    }
}

// Specialized Index implementation for Int
extension DataFrame where I == Int {
    private func validateIndexValueSync() -> Bool {
        let expectedCount = indexes.count
        return values.allSatisfy { $0.value.count == expectedCount }
    }
    
    public func sorted() -> DataFrame<Int, T, F> {
        // Create sorted indices and maintain value synchronization
        let sortedPairs = zip(indexes, 0..<indexes.count).sorted { $0.0 < $1.0 }
        let sortedIndices = sortedPairs.map { $0.0 }
        let originalPositions = sortedPairs.map { $0.1 }
        
        var sortedValues: [F: [T]] = [:]
        for (field, values) in self.values {
            sortedValues[field] = originalPositions.map { values[$0] }
        }
        
        return DataFrame(indexes: sortedIndices, values: sortedValues)
    }
    
    public func binarySearch(for index: Int) -> Int? {
        var left = 0
        var right = indexes.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            if indexes[mid] == index {
                return mid
            } else if indexes[mid] < index {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        return nil
    }
    
    public subscript(index: Int) -> Row? {
        guard let position = binarySearch(for: index) else { return nil }
        var row: Row = [:]
        for (field, values) in self.values {
            row[field] = values[position]
        }
        return row
    }
    
    public mutating func insert(index: Int, values: [F: T]) throws {
        guard validateIndexValueSync() else {
            throw DataFrameError.inconsistentDataSize
        }
        
        if let position = binarySearch(for: index) {
            // Update existing index
            for (field, value) in values {
                self.values[field]?[position] = value
            }
        } else {
            // Insert new index
            let insertPosition = indexes.firstIndex { $0 > index } ?? indexes.count
            indexes.insert(index, at: insertPosition)
            
            // Insert values for provided fields
            for (field, value) in values {
                self.values[field, default: []].insert(value, at: insertPosition)
            }
            
            // Insert default values for other fields to maintain synchronization
            for field in self.fields where values[field] == nil {
                if self.values[field]?.count != indexes.count {
                    // Create a default value based on the type
                    let defaultValue: T
                    if let numericType = T.self as? any Numeric.Type {
                        defaultValue = numericType.zero as! T
                    } else if T.self is String.Type {
                        defaultValue = "" as! T
                    } else {
                        // For other types, we need to handle them specifically
                        throw DataFrameError.inconsistentDataSize
                    }
                    self.values[field]?.insert(defaultValue, at: insertPosition)
                }
            }
        }
    }
    
    public func range(from start: Int, to end: Int) -> DataFrame<Int, T, F>? {
        guard let startIndex = indexes.firstIndex(where: { $0 >= start }),
              let endIndex = indexes.lastIndex(where: { $0 <= end }) else {
            return nil
        }
        
        let rangeIndexes = Array(indexes[startIndex...endIndex])
        var rangeValues: [F: [T]] = [:]
        
        for (field, values) in self.values {
            rangeValues[field] = Array(values[startIndex...endIndex])
        }
        
        return DataFrame(indexes: rangeIndexes, values: rangeValues)
    }
    
    public mutating func remove(at index: Int) throws {
        guard let position = binarySearch(for: index) else { return }
        
        indexes.remove(at: position)
        for field in self.fields {
            self.values[field]?.remove(at: position)
        }
        
        guard validateIndexValueSync() else {
            throw DataFrameError.inconsistentDataSize
        }
    }
    
    public func isSorted() -> Bool {
        guard indexes.count > 1 else { return true }
        for i in 1..<indexes.count {
            if indexes[i] < indexes[i-1] {
                return false
            }
        }
        return true
    }
    
    public func validate() -> Bool {
        return validateIndexValueSync() && isSorted()
    }
}

// Add async/await support
extension DataFrame {
    public func asyncMap<U>(_ transform: @escaping (T) async throws -> U) async throws -> DataFrame<I, U, F> {
        var newValues: [F: [U]] = [:]
        let newIndexes = self.indexes
        
        // Process each field in parallel
        try await withThrowingTaskGroup(of: (F, [U]).self) { group in
            for (field, values) in self.values {
                group.addTask {
                    var transformed: [U] = []
                    transformed.reserveCapacity(values.count)
                    
                    for value in values {
                        let transformedValue = try await transform(value)
                        transformed.append(transformedValue)
                    }
                    
                    return (field, transformed)
                }
            }
            
            // Collect results
            for try await (field, transformedValues) in group {
                newValues[field] = transformedValues
            }
        }
        
        return DataFrame<I, U, F>(indexes: newIndexes, values: newValues)
    }
    
    public func parallelMap<U>(_ transform: @escaping (T) -> U) -> DataFrame<I, U, F> {
        var newValues: [F: [U]] = [:]
        let newIndexes = self.indexes
        
        // Use DispatchQueue for parallel processing
        let queue = DispatchQueue(label: "com.rzdata.parallelMap", attributes: .concurrent)
        let group = DispatchGroup()
        let lock = NSLock()
        
        for (field, values) in self.values {
            group.enter()
            queue.async {
                var transformed: [U] = []
                transformed.reserveCapacity(values.count)
                
                for value in values {
                    transformed.append(transform(value))
                }
                
                lock.lock()
                newValues[field] = transformed
                lock.unlock()
                group.leave()
            }
        }
        
        group.wait()
        return DataFrame<I, U, F>(indexes: newIndexes, values: newValues)
    }
}

// Basic operations
extension DataFrame {
    // Create new column from single column
    public mutating func addColumn(_ newField: F, from field: F, transform: (T) -> T) {
        guard let values = self.values[field] else { return }
        self.values[newField] = values.map(transform)
    }
    
    // Create new column from multiple columns
    public mutating func addColumn(_ newField: F, from fields: [F], transform: ([T]) -> T) {
        guard !fields.isEmpty else { return }
        let fieldValues = fields.compactMap { self.values[$0] }
        guard !fieldValues.isEmpty else { return }
        
        var newValues: [T] = []
        for i in 0..<self.count {
            let values = fieldValues.map { $0[i] }
            newValues.append(transform(values))
        }
        self.values[newField] = newValues
    }
}

//MARK: - Index Operations

extension DataFrame {
    /// Returns a new DataFrame containing only the indexes that are common with the provided indexes
    /// - Parameter other: The indexes to reduce to
    /// - Returns: A new DataFrame with only the common indexes
    public func reducedToCommonIndex(indexes other: [I]) -> DataFrame {
        // handle simple cases
        if self.indexes.count == 0 || self.indexes == other {
            return self
        }
        
        var newIndexes: [I] = []
        var newValues: [F:[T]] = [:]
        self.fields.forEach { newValues[$0] = [] }

        if other.count > 0 {
            var otherIdx: Int = 0
            var otherIndex: I = other.first!
            
            for (index,row) in self {
                while (otherIndex < index && otherIdx < (other.count - 1)) {
                    otherIdx += 1
                    otherIndex = other[otherIdx]
                }
                if index == otherIndex {
                    for (field,value) in row {
                        newValues[field]?.append(value)
                    }
                    newIndexes.append(index)
                }
            }
        }
        return DataFrame(indexes: newIndexes, values: newValues)
    }

    /// Subscript access to a range of rows
    /// - Parameter range: The range of rows to access
    /// - Returns: A new DataFrame containing only the specified rows
    public subscript(range: Range<Int>) -> DataFrame {
        guard !range.isEmpty else { return DataFrame(fields: self.fields) }
        guard range.lowerBound >= 0 && range.upperBound <= self.count else {
            return DataFrame(fields: self.fields)
        }
        
        var rv = DataFrame(fields: self.fields)
        rv.indexes = [I](self.indexes[range])
        for (field, values) in self.values {
            rv.values[field] = [T](values[range])
        }
        return rv
    }

    /// Subscript access to specific columns
    /// - Parameter columns: The set of columns to access
    /// - Returns: A new DataFrame containing only the specified columns
    public subscript(columns: Set<F>) -> DataFrame {
        let validColumns = columns.intersection(Set(self.fields))
        guard !validColumns.isEmpty else { return DataFrame(fields: []) }
        
        var rv = DataFrame(fields: Array(validColumns))
        rv.indexes = self.indexes
        for field in validColumns {
            rv.values[field] = self.values[field]
        }
        return rv
    }
}

//MARK: - Floating Point Specialization

extension DataFrame where T: FloatingPoint {
    /// Returns a new DataFrame with NaN and infinite values removed from specified fields
    /// - Parameters:
    ///   - fields: The fields to check for NaN/infinite values
    ///   - includeAllFields: If true, include all fields in the output DataFrame
    /// - Returns: A new DataFrame with invalid values removed
    public func dropna(fields: [F], includeAllFields: Bool = false) -> DataFrame {
        let outputFields = includeAllFields ? self.fields : fields.compactMap({ self.values[$0] != nil ? $0 : nil })
        let checkFields = fields.compactMap { self.values[$0] != nil ? $0 : nil }
        
        guard outputFields.count > 0 else { return self }
        
        var rv = DataFrame(fields: outputFields)
        rv.reserveCapacity(self.count)
        
        for (idx,index) in self.indexes.enumerated() {
            var valid: Bool = true
            for field in checkFields {
                let val = self.values[field]![idx]
                if !val.isFinite {
                    valid = false
                    break
                }
            }
            if valid {
                rv.unsafeFastAppend(fields: outputFields, elements: outputFields.map { self.values[$0]![idx] }, for: index)
            }
        }
        return rv
    }
}

//MARK: - Equatable Specialization

extension DataFrame where T: Equatable {
    /// Returns a new DataFrame containing only rows where the specified fields change value
    /// - Parameter fields: The fields to monitor for value changes
    /// - Returns: A new DataFrame with only rows where values change
    public func dataFrameForValueChange(fields: [F]) -> DataFrame {
        let selectFields = fields.compactMap { self.values[$0] != nil ? $0 : nil }
        
        var rv = DataFrame(fields: selectFields)
        
        guard selectFields.count > 0 else { return rv }
        
        var last: [T] = []
        
        for (index,row) in self {
            var add: Bool = (last.count != selectFields.count)

            let vals = selectFields.map { row[$0]! }
            if !add {
                add = (vals != last)
            }
            last = vals
            if add {
                rv.unsafeFastAppend(fields: selectFields, elements: vals, for: index)
            }
        }
        
        return rv
    }
}

