//
//  TimedDataByField.swift
//  FlightLog1000
//
//  Created by Brice Rosenzweig on 24/04/2022.
//

import Foundation
import CoreLocation
import Accelerate

//DataFrame
public struct DataFrame<I : Comparable & Hashable,T,F : Hashable> {
    //MARK: - Type definitions
    public enum DataFrameError : Error {
        case inconsistentIndexOrder
        case inconsistentDataSize
        case unknownField(F)
    }
    
    //Row
    public typealias Row = [F:T]
    
    public struct Point {
        public let index : I
        public let value : T
    }
    
    //Column
    public struct Column {
        public let indexes : [I]
        public let values : [T]
        
        public var first : Point? { guard let i = indexes.first, let v = values.first else { return nil }; return Point(index: i, value: v) }
        public var last : Point? { guard let i = indexes.last, let v = values.last else { return nil }; return Point(index: i, value: v) }
        public var count : Int { return indexes.count }
        
        public func dropFirst(_ k : Int) -> Column {
            return Column(indexes: [I]( self.indexes.dropFirst(k) ), values: [T]( self.values.dropFirst(k)) )
        }
        
        public init(indexes: [I], values: [T]) {
            self.indexes = indexes
            self.values = values
        }
        public subscript(_ idx : Int) -> T? {
            return self.values.indices.contains(idx) ? self.values[idx] : nil
        }
    }
    
    
    //MARK: - stored property
    public private(set) var indexes : [I]
    public private(set) var values : [F:[T]]
    
    //MARK: - calc property
    public var fields : [F] { return Array(values.keys) }
    public var count : Int { return indexes.count }
    
    //MARK: - init and setup
    public init(fields : [F]){
        indexes = []
        values = [:]
        for field in fields {
            values[field] = []
        }
    }
    
    public init(indexes : [I], values: [F:[T]]){
        self.indexes = indexes
        self.values = values
    }
    
    public init() {
        indexes = []
        values = [:]
    }
    
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
                // for some reason doing it manually here is much faster than calling function on dataframe?
                self.indexes.append(index)
                for (field,element) in zip(fields,row) {
                    //self.values[field, default: []].append(element)
                    self.values[field]?.append(element)
                }

                lastindex = index
            }
        }
    }
    
    private init(indexes : [I], values: [F:[T]], fields: [F]) throws{
        var v : [F:[T]] = [:]
        for field in fields {
            if let c = values[field] {
                v[field] = c
            }else{
                throw DataFrameError.unknownField(field)
            }
        }
        self.indexes = indexes
        self.values = v
    }
    
    mutating public func reserveCapacity(_ capacity : Int){
        indexes.reserveCapacity(capacity)
        for k in values.keys {
            values[k]?.reserveCapacity(capacity)
        }
    }
    
    mutating public func clear(fields : [F] = []) {
        indexes = []
        values = [:]
        for field in fields {
            values[field] = []
        }
    }
    
    //MARK: - modify, append
    private mutating func indexCheckAndUpdate(index : I) throws {
        if let last = indexes.last {
            if index > last {
                indexes.append(index)
            }else if index < last {
                throw DataFrameError.inconsistentIndexOrder
            }
        }else{
            // nothing yet, insert date
            indexes.append(index)
        }
    }

    private mutating func updateField(field : F, element : T) throws {
        values[field, default: []].append(element)

        if values[field, default: []].count != indexes.count {
            throw DataFrameError.inconsistentDataSize
        }
    }
    public mutating func append(field : F, element : T, for index : I) throws {
        try self.indexCheckAndUpdate(index: index)
        
        try self.updateField(field: field, element: element)
    }
    
    public mutating func unsafeFastAppend(field : F, element : T, for index : I) throws {
        if indexes.last == nil || indexes.last! != index {
            self.indexes.append(index)
        }
        values[field, default: []].append(element)
    }
    
    public mutating func append(fieldsValues : [F:T], for index : I) throws {
        try self.indexCheckAndUpdate(index: index)

        for (field,value) in fieldsValues {
            try self.updateField(field: field, element: value)
        }
    }

    public mutating func unsafeFastAppend(fields : [F], elements : [T], for index : I) {
        self.indexes.append(index)
        for (field,element) in zip(fields,elements) {
            //self.values[field, default: []].append(element)
            self.values[field, default: []].append(element)
        }
    }
    
    
    public mutating func append(fields : [F], elements: [T], for index : I) throws {
        try self.indexCheckAndUpdate(index: index)
        
        for (field,element) in zip(fields,elements) {
            try self.updateField(field: field, element: element)
        }
    }
    
    public func dropFirst(index : I) -> DataFrame? {
        guard let found = self.indexes.firstIndex(of: index) else { return nil }
        
        var rv = DataFrame(fields: [F](self.values.keys))
        rv.indexes = [I](self.indexes.dropFirst(found))
        for (field,values) in self.values {
            rv.values[field] = [T](values.dropFirst(found))
        }
        return rv
    }
    
    public func dropFirst(field : F, minimumMatchCount : Int = 1, matching : ((T) -> Bool)) -> DataFrame? {
        
        guard let fieldValues = self.values[field]
        else {
            return nil
        }
        
        var rv = DataFrame(fields: [F](self.values.keys))

        var found : Int = -1
        var matchCount : Int = 0
        for (idx,value) in fieldValues.enumerated() {
            if matching(value) {
                matchCount += 1
            }else{
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
    
    public func dropLast(field : F, matching : ((T) -> Bool)) -> DataFrame? {
        
        guard let fieldValues = self.values[field]
        else {
            return nil
        }
        
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
    
    public mutating func add(field : F, column : Column) {
        if indexes == column.indexes {
            self.values[field] = column.values
        }
    }
    
    //MARK: - Merge
    
    mutating public func merge(with other : DataFrame){
        let merged = self.merged(with: other)

        self.indexes = merged.indexes
        self.values = merged.values
    }

    /// merge two dataframes
    /// if the indexes are not the same, the result will be a dataframe with the union of the indexes
    /// if the indexes are the same, the values will use the values from the first dataframe
    public func merged(with other : DataFrame) -> DataFrame{
        // iterate over indexes of other
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
                }// else leave it at the last value
                
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
                }// else leave it at last value
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
    
    /// Returned array sliced from start to end.
    /// - Parameters:
    ///   - start: any index that are greater than or equal to start are included. if nil starts at the begining
    ///   - end: any index that are strictly less than end are included, if nil ends at the end
    /// - Returns: new indexvaluesbyfield
    public func sliced(start : I? = nil, end : I? = nil) -> DataFrame {
        guard self.indexes.count > 0 && ( start != nil || end != nil ) else { return self }
        
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
    
    
    public func dataFrame(for fields : [F]) throws -> DataFrame {
        return try DataFrame(indexes: self.indexes, values: self.values, fields:    fields)
    }

    //MARK: - Extend
    mutating public func extend(output : F, input : F, transform : (T) -> T) {
        guard let inputValues = self.values[input] else { return }
        var outputValues : [T] = []
        outputValues.append(contentsOf: inputValues.map(transform))
        self.values[output] = outputValues
    }

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
    //MARK: - access
    public func has(fields : [F]) -> Bool {
        let queryFieldSet = Set(fields)
        let thisFieldSet = Set(self.fields)
        return queryFieldSet.isSubset(of: thisFieldSet)
    }
    
    public func has(field : F) -> Bool {
        return self.values[field] != nil
    }
    
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
        }else{
            return Point(index: lastDate, value: lastValue)
        }
    }

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
        }else{
            return Point(index: firstDate, value: firstValue)
        }
    }
    
    public func point(for field : F, at index : Int) -> Point? {
        guard let fieldValues = self.values[field], index < self.indexes.count else { return nil }
        let value = fieldValues[index]
        let date = self.indexes[index]
        return Point(index: date, value: value)
    }

    public func value(for field : F, at index : Int) -> T? {
        guard let fieldValues = self.values[field], index < self.indexes.count else { return nil }
        let value = fieldValues[index]
        return value
    }
    
    public func row(at index : Int) -> Row {
        var rv : Row = [:]
        for (field,values) in self.values {
            if let value = values[safe: index] {
                rv[field] = value
            }
        }
        return rv
    }
    
    public func column(for field : F) -> Column? {
        guard let values = self.values[field] else { return nil }
        return Column(indexes: self.indexes, values: values)
    }
    public subscript(_ field : F) -> Column? {
        return self.column(for: field)
    }
    
    //MARK: - index
    
    public func reducedToCommonIndex(indexes other : [I]) -> DataFrame{
        // handle simple cases
        if self.indexes.count == 0 || self.indexes == other {
            return self
        }
        
        var newIndexes : [I] = []
        var newValues : [F:[T]] = [:]
        self.fields.forEach { newValues[$0] = [] }

        if other.count > 0 {
            var otherIdx : Int = 0
            var otherIndex : I = other.first!
            
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
    
}

//MARK: - Floating point specialisation
extension DataFrame where T : FloatingPoint {
    public func dropna(fields : [F], includeAllFields : Bool = false) -> DataFrame {
        let outputFields = includeAllFields ? self.fields : fields.compactMap( { self.values[$0] != nil ? $0 : nil } )
        let checkFields = fields.compactMap { self.values[$0] != nil ? $0 : nil }
        
        guard outputFields.count > 0 else { return self }
        
        var rv = DataFrame(fields: outputFields)
        rv.reserveCapacity(self.count)
        
        for (idx,index) in self.indexes.enumerated() {
            var valid : Bool = true
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


//MARK: - Equatable specialisation
extension DataFrame where T : Equatable {
    public func dataFrameForValueChange(fields : [F]) -> DataFrame {
        let selectFields = fields.compactMap { self.values[$0] != nil ? $0 : nil }
        
        var rv = DataFrame(fields: selectFields)
        
        guard selectFields.count > 0 else { return rv }
        
        var last : [T] = []
        
        for (index,row) in self {
            var add : Bool = (last.count != selectFields.count)

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


//MARK: - Sequence/iterators
extension DataFrame : Sequence {
    ///MARK: Iterator
    public struct DataFrameIterator : IteratorProtocol {
        let dataFrame : DataFrame
        var idx : Int
        var row : Row = [:]
        
        public init(_ indexedValues : DataFrame) {
            self.dataFrame = indexedValues
            self.idx = 0
        }
        public mutating func next() -> (I,Row)? {
            guard idx < dataFrame.indexes.count else { return nil }
                
            let index = dataFrame.indexes[idx]
            for (field,serie) in dataFrame.values {
                row[field] = serie[idx]
            }
            idx += 1
            return (index,row)
        }
    }
    public func makeIterator() -> DataFrameIterator {
        return DataFrameIterator(self)
    }
}

extension DataFrame.Column : Sequence {
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
    public func makeIterator() -> ColumnIterator {
        return ColumnIterator(self)
    }
}

extension DataFrame.Column where T : Hashable {
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

