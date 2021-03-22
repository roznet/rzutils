//
//  MyClass.h
//  
//
//  Created by Brice Rosenzweig on 21/03/2021.
//

@import Foundation;
#import "GCStatsDataSerie.h"

NS_ASSUME_NONNULL_BEGIN

@interface GCStatsDataSerie (Categorical)

/**
 Add new point for a category, if category exists value will be added (sum)
 */
-(void)addDataPointForCategory:(NSString*)label value:(double)value;
/**
 Add new point for a category, if category exists value will be replaced with the new value
 */
-(void)setDataPointForCategory:(NSString*)label value:(double)value;

@end

NS_ASSUME_NONNULL_END
