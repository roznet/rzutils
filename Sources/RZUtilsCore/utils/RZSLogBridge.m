//  MIT Licence
//
//  Created on 05/11/2016.
//
//  Copyright (c) 2016 Brice Rosenzweig.
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

#import "RZLog.h"
#import "RZSLogBridge.h"

@implementation RZSLogBridge
+(void)logError:(NSString*)funcName
           path:(NSString*)path
           line:(NSInteger)line
        message:(NSString*)msg{
#if TARGET_IPHONE_SIMULATOR || DEBUG
    NSLog(@"^[%@]: %@", funcName,  msg);
#endif
    RZlogLevels level = RZLogError;
    [LCLLogFile logWithIdentifier:RZLog_components[level]
                            level:(unsigned int)level
                             path:[path cStringUsingEncoding:NSUTF8StringEncoding]
                             line:(unsigned)line
                         function:[funcName cStringUsingEncoding:NSUTF8StringEncoding]
                          message:msg];

}
+(void)logInfo:(NSString*)funcName
          path:(NSString*)path
          line:(NSInteger)line
       message:(NSString*)msg{
#if TARGET_IPHONE_SIMULATOR || DEBUG
    NSLog(@"^[%@]: %@", funcName,  msg);
#endif
    RZlogLevels level = RZLogInfo;
    [LCLLogFile logWithIdentifier:RZLog_components[level]
                            level:(unsigned int)level
                             path:[path cStringUsingEncoding:NSUTF8StringEncoding]
                             line:(unsigned)line
                         function:[funcName cStringUsingEncoding:NSUTF8StringEncoding]
                          message:msg];

}
+(void)logWarning:(NSString*)funcName
             path:(NSString*)path
             line:(NSInteger)line
          message:(NSString*)msg{
#if TARGET_IPHONE_SIMULATOR || DEBUG
    NSLog(@"^[%@]: %@", funcName,  msg);
#endif
    RZlogLevels level = RZLogWarning;
    [LCLLogFile logWithIdentifier:RZLog_components[level]
                            level:(uint32_t)level
                             path:[path cStringUsingEncoding:NSUTF8StringEncoding]
                             line:(unsigned)line
                         function:[funcName cStringUsingEncoding:NSUTF8StringEncoding]
                          message:msg];

}


+(void)logBridge:(RZlogLevels)level
    functionName:(NSString*)funcName
            path:(NSString*)path
            line:(NSInteger)line
         message:(NSString*)msg{
#if TARGET_IPHONE_SIMULATOR || DEBUG
    NSLog(@"^[%@]: %@", funcName,  msg);
#endif
    [LCLLogFile logWithIdentifier:RZLog_components[level]
                            level:(uint32_t)level
                             path:[path cStringUsingEncoding:NSUTF8StringEncoding]
                             line:(unsigned)line
                         function:[funcName cStringUsingEncoding:NSUTF8StringEncoding]
                          message:msg];
}


@end
