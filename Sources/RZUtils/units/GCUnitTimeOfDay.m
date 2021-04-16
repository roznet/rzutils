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

#import "GCUnitTimeOfDay.h"

#pragma mark -
@implementation GCUnitTimeOfDay
#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_calendar release];
    [_dateFormatter release];
    [super dealloc];
}
#endif

-(NSString*)formatDouble:(double)aDbl addAbbr:(BOOL)addAbbr{
    if (!_dateFormatter) {
        [self setDateFormatter:RZReturnAutorelease( [[NSDateFormatter alloc] init])];
        _dateFormatter.dateStyle = NSDateFormatterNoStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return [_dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:aDbl]];
}

-(double)axisKnobSizeFor:(double)range numberOfKnobs:(NSUInteger)n{
    return ceil(24./n);
}

-(NSArray*)axisKnobs:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max extendToKnobs:(BOOL)extend{

    if (nKnobs > 0) {// don't bother for edge case
        // |----------------------|
        // 0                      24
        //
        double size = ceil(24./(nKnobs))*3600.;
        NSDate * startDate = nil;
        NSTimeInterval interval;
        if (!self.calendar) {
            self.calendar = [NSCalendar currentCalendar];
        }
        [self.calendar rangeOfUnit:NSCalendarUnitDay startDate:&startDate interval:&interval forDate:[NSDate dateWithTimeIntervalSinceReferenceDate:x_min]];

        NSMutableArray * rv = [NSMutableArray arrayWithCapacity:nKnobs];

        for (NSUInteger i=0; i<nKnobs; i++) {
            double x = MIN(startDate.timeIntervalSinceReferenceDate+ size*(i+1), startDate.timeIntervalSinceReferenceDate+24.*3600.);

            [rv addObject:@(x)];
        }
        return rv;
    }
    return [super axisKnobs:nKnobs min:x_min max:x_max extendToKnobs:extend];
}



@end
