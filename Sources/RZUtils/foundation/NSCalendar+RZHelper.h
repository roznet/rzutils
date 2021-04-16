//
//  MyClass.h
//  
//
//  Created by Brice Rosenzweig on 16/04/2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCalendar (RZHelper)

-(NSArray<NSDate*>*)scheduleForComponent:(NSCalendarUnit)unit
                                fromDate:(NSDate*)fromDate
                              toDate:(NSDate*)toDate
                       referenceDate:(nullable NSDate*)referenceDateOrNil;

@end

NS_ASSUME_NONNULL_END
