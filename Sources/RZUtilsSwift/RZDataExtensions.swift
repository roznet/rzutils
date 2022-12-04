//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 03/12/2022.
//

import Foundation
import RZData
import RZUtils

extension DataFrame {
    
}


extension DataFrame  where T == Double, I == Date {
    
    public func dataSeries(from : I? = nil, to : I? = nil) -> [F:GCStatsDataSerie] {
        var rv : [F:GCStatsDataSerie] = [:]
        var started : Bool = false
        for (idx,runningdate) in self.indexes.enumerated(){
            if let to = to, runningdate > to {
                break
            }
            if from == nil || runningdate >= from! {
                if started {
                    for (field,values) in self.values {
                        rv[field]?.add(GCStatsDataPoint(date: runningdate, andValue: values[idx]))
                    }
                }else{
                    for (field,values) in self.values {
                        rv[field] = GCStatsDataSerie()
                        rv[field]?.add(GCStatsDataPoint(date: runningdate, andValue: values[idx]))
                    }
                    started = true
                }
            }
        }
        return rv
    }
}
 
extension ValueStats {

    public var gcUnit : GCUnit { return self.unit?.gcUnit ?? GCUnit.dimensionless() }
     //MARK: - Access
}


