//
//  MyClass.m
//  
//
//  Created by Brice Rosenzweig on 16/04/2021.
//

#import "NSCalendar+RZHelper.h"

@implementation NSCalendar (RZHelper)

-(NSArray<NSDate*>*)scheduleForComponent:(NSCalendarUnit)calUnit
                                fromDate:(NSDate*)fromDate
                              toDate:(NSDate*)toDate
                           referenceDate:(nullable NSDate*)referenceDateOrNil{
    NSTimeInterval tip = 0.0;
    
    NSDate * startDate = nil;
    NSDate * endDate = nil;
    
    NSDate * from_date = fromDate;
    NSDate * to_date   = toDate;

    NSDateComponents * comp = nil;

    NSCalendarOptions options = NSCalendarMatchNextTime;
    // Figure out start/end date
    if( referenceDateOrNil ){
        // Do rolling knobs
        comp = [self components:calUnit fromDate:referenceDateOrNil toDate:from_date options:options];
        startDate = [self dateByAddingComponents:comp toDate:referenceDateOrNil options:options];
        comp = [self components:calUnit fromDate:referenceDateOrNil toDate:to_date options:options];
        endDate = [self dateByAddingComponents:comp toDate:referenceDateOrNil options:options];
    }else{
        // do calendar knobs
        [self rangeOfUnit:calUnit startDate:&startDate interval:&tip forDate:from_date];
        comp = [self components:calUnit fromDate:startDate toDate:to_date options:options];
        endDate = [self dateByAddingComponents:comp toDate:startDate options:options];
    }
    
    comp = [self components:calUnit fromDate:startDate toDate:endDate options:options];

    NSInteger n = [comp valueForComponent:calUnit];
    NSMutableArray<NSDate*>*rv = [NSMutableArray array];
    for (NSInteger i = 0; i <= n; i++) {
        NSDate * one = [self dateByAddingUnit:calUnit value:(i-n) toDate:endDate options:options];
        [rv addObject:one];
    }
    
    // Stubs
    NSDate * first = rv.firstObject;
    NSDate * last  = rv.lastObject;
    
    if( [first compare:from_date] == NSOrderedDescending){
        NSDate * first = [self dateByAddingUnit:calUnit value:-(n+1) toDate:endDate options:options];
        [rv insertObject:first atIndex:0];
    }
    
    if( [last compare:to_date] == NSOrderedAscending){
        NSDate * last = [self dateByAddingUnit:calUnit value:1 toDate:endDate options:options];
        [rv addObject:last];
    }
    
    return rv;

}

@end
