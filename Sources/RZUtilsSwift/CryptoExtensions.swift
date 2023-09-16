//  MIT License
//
//  Created on 23/03/2023 for flyfunboarding
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
import CryptoKit

extension SHA256 {
    static func hash(string : String) -> SHA256Digest? {
        if let data = string.data(using: .utf8) {
            return SHA256.hash(data: data)
        }
        return nil
    }
}

extension SHA256Digest {
    var hashString : String {
        self.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension Insecure.SHA1 {
    static func hash(string : String) -> Insecure.SHA1.Digest? {
        if let data = string.data(using: .utf8) {
            return Insecure.SHA1.hash(data: data)
        }
        return nil
    }
}

extension Insecure.SHA1Digest {
    var hashString : String {
        self.compactMap { String(format: "%02x", $0) }.joined()
    }
}
