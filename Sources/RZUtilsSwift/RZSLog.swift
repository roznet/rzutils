//
//  RZSLog.swift
//  RZUtils
//
//  Created by Brice Rosenzweig on 24/07/2016.
//  Copyright © 2016 Brice Rosenzweig. All rights reserved.
//

import Foundation
import RZUtils
import OSLog

extension OSLogEntryLog {
    var levelDescription : String {
        switch self.level {
        case .undefined:
            return "UNDF"
        case .error:
            return "ERR "
        case .debug:
            return "DBG "
        case .notice:
            return "WARN"
        case .info:
            return "INFO"
        case .fault:
            return "FAUL"
        @unknown default:
            return "UNKN"
        }
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value : OSLogEntryLog) {
        //appendLiteral(value.date.formatted(date: .abbreviated, time: .standard))
        appendLiteral("\(value.date) \(value.processIdentifier):\(value.threadIdentifier)  [\(value.category)] \(value.levelDescription) \(value.composedMessage)")
    }
}
public struct RZLogger {
    public static var useOSLog : Bool = false
    
    let logger : Logger
    let category : String
    public init(subsystem: String, category: String){
        self.category = category
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    public func info(_ message : String, function : String = #function, file : String = #file, line : Int = #line) {
        if RZLogger.useOSLog {
            self.logger.info("\((file as NSString).lastPathComponent, privacy: .public):\(String(format: "%d", line), privacy: .public):\(function, privacy: .public) \(message, privacy: .public)")
        }else{
            RZSLogBridge.logInfo(function, path: file , line: line, message: "[\(category)] \(message)")
        }
    }
    public func error(_ message : String, function : String = #function, file : String = #file, line : Int = #line) {
        if RZLogger.useOSLog {
            self.logger.error("\((file as NSString).lastPathComponent, privacy: .public):\(String(format: "%d", line), privacy: .public):\(function, privacy: .public) \(message, privacy: .public)")
        }else{
            RZSLogBridge.logError(function, path: file , line: line, message: "[\(category)] \(message)")
        }
    }
    public func warning(_ message : String, function : String = #function, file : String = #file, line : Int = #line) {
        if RZLogger.useOSLog {
            self.logger.notice("\((file as NSString).lastPathComponent, privacy: .public):\(String(format: "%d", line), privacy: .public):\(function, privacy: .public) \(message, privacy: .public)")
        }else{
            RZSLogBridge.logWarning(function, path: file , line: line, message: "[\(category)] \(message)")

        }
    }
}

extension Logger {
   
    public static func logEntriesContent(hours : Int = 1) -> String {
        if RZLogger.useOSLog {
            return logEntriesFormatted(hours: hours).joined(separator: "\n")
        }else{
            return RZLogFileContent() ?? "<Empty Log>"
        }
    }
    
    public static func logEntriesFormatted(hours : Int = 1) -> [String] {
        if RZLogger.useOSLog {
            var rv : [String] = []
            do {
                let l = try Self.logEntries(hours: hours)
                for one in l {
                    rv.append("\(one)")
                }
            }catch{
                rv.append(error.localizedDescription)
            }
            return rv
        }else{
            return RZLogFileContent().components(separatedBy: CharacterSet.newlines)
        }
    }
    
    public static func logEntries(hours : Int = 1) throws -> [OSLogEntryLog]{
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        
        let oneHour = logStore.position(date: Date().addingTimeInterval(-3600*TimeInterval(hours)))
        
        let entries = try logStore.getEntries(at: oneHour)
        
        return entries.compactMap { $0 as? OSLogEntryLog }.filter { $0.subsystem == Bundle.main.bundleIdentifier! }
    }

}


public class RZSLog {
    
    public class func info( _ message:String, functionName:String = #function, fileName:String = #file, lineNumbe:Int = #line ){
        RZSLogBridge.logInfo(functionName, path: fileName , line: lineNumbe, message: message)
    }
    public class func error( _ message:String, functionName:String = #function, fileName:String = #file, lineNumbe:Int = #line ){
        RZSLogBridge.logError(functionName, path: fileName , line: lineNumbe, message: message)
    }
    public class func warning( _ message:String, functionName:String = #function, fileName:String = #file, lineNumbe:Int = #line ){
        RZSLogBridge.logWarning(functionName, path: fileName , line: lineNumbe, message: message)
    }

}
