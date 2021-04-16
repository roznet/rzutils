//  MIT Licence
//
//  Created on 16/04/2021.
//
//  Copyright (c) 2021 Brice Rosenzweig.
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


#import "GCUnitDate.h"


@implementation GCUnitDate

@synthesize dateFormatter;
#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_calendar release];
    [dateFormatter release];
    [super dealloc];
}
#endif

-(double)axisKnobSizeFor:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max{
    double range = x_max - x_min;
    
    if (self.useCalendarUnit) {
        if (self.calendarUnit == NSCalendarUnitWeekOfYear || self.calendarUnit == NSCalendarUnitMonth) {
            double oneday = 24.*60.*60.;
            return ceil(range/nKnobs/oneday)* oneday;
        }else if(self.calendarUnit == NSCalendarUnitYear){
            double onemonth = 24.*60.*60.*365./12.;
            return ceil(range/nKnobs/onemonth)* onemonth;
        }
    }
    return [super axisKnobSizeFor:nKnobs min:x_min max:x_max];
}

-(NSString*)formatDouble:(double)aDbl{
    if (!dateFormatter) {
        [self setDateFormatter:RZReturnAutorelease( [[NSDateFormatter alloc] init])];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    if (self.useCalendarUnit) {
        if (!self.calendar) {
            self.calendar = [NSCalendar currentCalendar];

        }
    }
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:aDbl]];
}

-(NSArray*)axisKnobs:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max extendToKnobs:(BOOL)extend{

    if (self.useCalendarUnit && nKnobs > 0) {// don't bother for edge case
        if (!self.calendar) {
            self.calendar = [NSCalendar currentCalendar];
        }
        NSDate * startDate = nil;
        NSTimeInterval interval;
        [self.calendar rangeOfUnit:self.calendarUnit startDate:&startDate interval:&interval forDate:[NSDate dateWithTimeIntervalSinceReferenceDate:x_min]];
        NSDateComponents * diff = [self.calendar components:self.calendarUnit fromDate:startDate toDate:[NSDate dateWithTimeIntervalSinceReferenceDate:x_max] options:0];

        NSDateComponents * increment = RZReturnAutorelease([[NSDateComponents alloc] init]);

        NSUInteger n = 1;
        if (self.calendarUnit==NSCalendarUnitMonth) {
            n = diff.month;
            [increment setMonth:MAX(n/nKnobs,1)];
        }else if (self.calendarUnit==NSCalendarUnitWeekOfYear){
            n = diff.weekOfYear;
            [increment setWeekOfYear:MAX(n/nKnobs,1)];
        }else if (self.calendarUnit==NSCalendarUnitYear){
            n = diff.year;
            [increment setYear:MAX(n/nKnobs,1)];
        }
        n = MIN(n, 100)+1;
        NSMutableArray * rv = [NSMutableArray arrayWithCapacity:n];
        while (n > 0 && startDate.timeIntervalSinceReferenceDate<x_max) {
            n--;// protection against big while loop
            [rv addObject:@(startDate.timeIntervalSinceReferenceDate)];
            startDate = [self.calendar dateByAddingComponents:increment toDate:startDate options:0];
        }
        if (startDate.timeIntervalSinceReferenceDate>=x_max) {
            [rv addObject:@(x_max)];
        }
        return rv;
    }else{
        return [super axisKnobs:nKnobs min:x_min max:x_max extendToKnobs:extend];
    }
}


-(NSString*)formatDoubleNoUnits:(double)aDbl{
    return [self formatDouble:aDbl];
}
@end

