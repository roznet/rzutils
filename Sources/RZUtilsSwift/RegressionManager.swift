//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 11/01/2021.
//

import Foundation

public class RegressionManager  {
    
    let testName : String
    let referencePath : String

    public var recordMode = false
    
    public init(cls : AnyClass, referencePath : String = #filePath) {
        self.testName = String(describing: cls)
        self.referencePath = extractPath(filepath: referencePath)
    }
    
    public init(name : String, referencePath : String = #filePath){
        self.testName = name
        self.referencePath = extractPath(filepath: referencePath)
    }
    
    public func retrieve<T : Codable>(object : T, identifier : String, function : String = #function) throws -> T  {
        let objectURL = try self.url(identifier:identifier,function:function)
        
        if self.recordMode {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(object)
            try data.write(to: objectURL)
            return object
        }else{
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: objectURL)
            return try decoder.decode(T.self, from: data)
        }
    }
    
    func url(identifier: String, function : String) throws -> URL {
        let charset : CharacterSet = CharacterSet.urlPathAllowed.inverted
        let path = self.referenceDirectory
        let directory = "\(path)/\(self.testName)".trimmingCharacters(in: charset)
        if !FileManager.default.fileExists(atPath: directory) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        var functionName = function
        // Special case, most test function has no argument
        // no need to have () in the filename
        if functionName.hasSuffix("()") {
            functionName.removeLast(2)
        }
        let filename = "\(functionName)_\(identifier).regobj".trimmingCharacters(in: charset)
        return URL(fileURLWithPath: "\(directory)/\(filename)")
    }
    
    var referenceDirectory : String {
        
        return "\(self.referencePath)/.regression"
    }
}

extension RegressionManager : CustomStringConvertible {
    public var description : String {
        return "RegressionManager(\(self.testName))"
    }
}

func extractPath(filepath : String) -> String {
    var isDir : ObjCBool = false
    var directoryPath : String = filepath
    repeat {
        if !FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDir){
            break;
        }
        if !isDir.boolValue {
            directoryPath = (directoryPath as NSString).deletingLastPathComponent
        }
        
    } while ( !isDir.boolValue && directoryPath.count > 1)
    
    return directoryPath
}

