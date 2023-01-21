//
//  TimedDataByField.swift
//  FlightLog1000
//
//  Created by Brice Rosenzweig on 24/04/2022.
//

import Foundation
import CoreLocation

//DataFrame
public struct DataFrame<I : Comparable,T,F : Hashable> {
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

extension DataFrame  where T == Double {
    public func valueStats(from : I, to : I, units : [F:Dimension] = [:]) -> [F:ValueStats] {
        var rv : [F:ValueStats] = [:]
        var started : Bool = false
        for (idx,runningdate) in self.indexes.enumerated(){
            if runningdate > to {
                break
            }
            if runningdate >= from {
                if started {
                    for (field,values) in self.values {
                        rv[field]?.update(double: values[idx])
                    }
                }else{
                    for (field,values) in self.values {
                        rv[field] = ValueStats(value: values[idx], weight: 1.0, unit: units[field])
                    }
                    started = true
                }
            }
        }
        return rv
    }
    
    public func max(for field : F) -> T? {
        guard let fieldValues = self.values[field] else { return nil }
        let value = fieldValues.max()
        return value
    }
    
    public func min(for field : F) -> T? {
        guard let fieldValues = self.values[field] else { return nil }
        let value = fieldValues.min()
        return value
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

