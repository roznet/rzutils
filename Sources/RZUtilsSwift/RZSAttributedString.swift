//
//  RZSAttributedString.swift
//  RZUtilsSwift
//
//  Created by Brice Rosenzweig on 12/08/2017.
//  Copyright © 2017 Brice Rosenzweig. All rights reserved.
//

import Foundation

extension NSAttributedString {
    static public func convertObjcAttributesDict( attributes: [String:Any]?) -> [NSAttributedString.Key:Any]? {
        var rv : [NSAttributedString.Key:Any]?
        
        if let attributes = attributes {
            rv = Dictionary(uniqueKeysWithValues:
                attributes.lazy.map { (NSAttributedString.Key($0.key), $0.value) }
            )
        }
        return rv
    }
}

extension String {
    public enum TruncationPosition {
        case head
        case middle
        case tail
    }
    
    public func truncated(limit : Int, position: TruncationPosition = .middle, ellipsis: String = "...") -> String {
        guard self.count > limit else { return self }
        
        let keep = limit - ellipsis.count
        switch position {
        case .head:
            return ellipsis + self.suffix(keep)
        case .tail:
            return self.prefix(keep) + ellipsis
        case .middle:
            let prefix = self.prefix(keep/2)
            let suffix = self.suffix(limit-ellipsis.count-prefix.count)
            
            return "\(prefix)\(ellipsis)\(suffix)"
        }
    }
}
