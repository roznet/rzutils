//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 19/01/2021.
//

import Foundation

extension Collection {
    @inlinable public subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
