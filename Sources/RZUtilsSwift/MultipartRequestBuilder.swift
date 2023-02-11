//
//  MultipartRequest.swift
//
//
//  Created by Brice Rosenzweig on 03/02/2023.
//

import Foundation

extension Data {
    mutating func append(_ str : String, encoding: String.Encoding = .utf8) {
        guard let strData = str.data(using: encoding) else { return }
        self.append(strData)
    }
}

public class MultipartRequestBuilder {

    static let separator = "\r\n"

    let boundary : String
    var data : Data
    var contentType : String
    let url : URL
    
    public init(url : URL){
        self.url = url
        self.boundary = "\(UUID().uuidString)"
        self.data = Data()
        self.contentType = "multipart/form-data; boundary=\(self.boundary)"
    }

    func addBoundary(final : Bool = false){
        self.data.append("--"+self.boundary+(final ? "--" : MultipartRequestBuilder.separator))
    }
    
    public func addField(name : String, value : String){
        self.addBoundary()
        self.data.append("Content-Disposition: form-data; name=\"\(name)\"\(MultipartRequestBuilder.separator)\(MultipartRequestBuilder.separator)")
        self.data.append(value+MultipartRequestBuilder.separator)
    }
    public func addFields(fields : [String:String]){
        for (name,value) in fields {
            self.addField(name: name, value: value)
        }
    }

    public func addFile(name : String, filename : String, data : Data, mimeType : String){
        self.addBoundary()
        self.data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\(MultipartRequestBuilder.separator)")
        self.data.append("Content-Type: \(mimeType)\(MultipartRequestBuilder.separator)\(MultipartRequestBuilder.separator)")
        self.data.append(data)
        self.data.append(MultipartRequestBuilder.separator)
    }

    public func addFile(name : String, filename : String, url : URL, mimeType : String){
        if let data = try? Data(contentsOf: url){
            self.addFile(name: name, filename: filename, data: data, mimeType: mimeType)
        }
    }

    public func request(cachePolicy : URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData) -> URLRequest {
        self.addBoundary(final: true)
        var request = URLRequest(url: self.url, cachePolicy: cachePolicy)
        request.httpMethod = "POST"
        request.setValue(self.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = self.data
        return request
    }
}   
        
