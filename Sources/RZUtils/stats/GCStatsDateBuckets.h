//  MIT Licence
//
//  Created on 19/12/2013.
//
//  Copyright (c) 2013 Brice Rosenzweig.
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

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface GCStatsDateBuckets : NSObject

@property (nonatomic,retain,nullable) NSDate * refOrNil;
@property (nonatomic,assign) NSCalendarUnit calendarUnit;

@property (nonatomic,retain,nullable) NSDate * bucketStart;
@property (nonatomic,retain,nullable) NSDate * bucketEnd;

@property (nonatomic,retain,nullable) NSDateComponents * componentUnit;
@property (nonatomic,retain) NSCalendar * calendar;

-(GCStatsDateBuckets*)initFor:(NSCalendarUnit)unit referenceDate:(nullable NSDate*)refOrNil andCalendar:(NSCalendar*)cal;
+(GCStatsDateBuckets*)statsDateBucketFor:(NSCalendarUnit)unit referenceDate:(nullable NSDate*)refOrNil andCalendar:(NSCalendar*)cal;

/// Will update the bucket to contains date.
/// Will return true if the bucket changed and bucketStart/bucketEnd were updated, or false if it stayed the same.
/// @param date to check
-(BOOL)bucket:(nonnull NSDate*)date;

/// check if a date is in the current bucket
/// @param date to check
-(BOOL)contains:(nonnull NSDate*)date;
@end

NS_ASSUME_NONNULL_END
