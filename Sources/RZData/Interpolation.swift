//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 14/05/2023.
//

import Foundation
import Accelerate
extension DataFrame where T == Double, I == Double {
 
    func interpolate(indexes : [I]) -> DataFrame {
        return self
    }
}

extension DataFrame where T == Double, I == Date {
    
}
