//  MIT License
//
//  Created on 04/06/2023 for flyfunboarding
//
//  Copyright (c) 2023 Brice Rosenzweig
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//



import Foundation
import SwiftUI
import UIKit

extension Color {
    public init(rgb: String) {
        let rgbValues = rgb
            .trimmingCharacters(in: CharacterSet(charactersIn: "rgb()"))
            .components(separatedBy: ",")
            .compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
            .map { CGFloat($0 / 255.0) }
        
        guard rgbValues.count == 3 else {
            self.init(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
            return
        }
        self.init(.sRGB, red: Double(rgbValues[0]), green: Double(rgbValues[1]), blue: Double(rgbValues[2]), opacity: 1.0)
    }

    public var rgb: String {
        if let components = UIColor(self).cgColor.components {
            let r = components[0]
            let g = components[1]
            let b = components[2]
            return "rgb(\(lroundf(Float(r) * 255)), \(lroundf(Float(g) * 255)), \(lroundf(Float(b) * 255)))"
        }
        return "rgb(255, 255, 255)"
    }
    
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
    
    public var hex: String {
        if let components = UIColor(self).cgColor.components {
            let r = components[0]
            let g = components[1]
            let b = components[2]
            return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
        }
        return "#FFFFFF"
    }

}

