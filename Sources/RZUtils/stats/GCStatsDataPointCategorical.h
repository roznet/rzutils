//
//  MyClass.h
//  
//
//  Created by Brice Rosenzweig on 21/03/2021.
//

@import Foundation;
#import "GCStatsDataPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface GCStatsDataPointCategorical : GCStatsDataPoint
@property (nonatomic,strong) NSString * categoryLabel;

+(GCStatsDataPointCategorical*)dataPointForCategory:(NSString*)label andValue:(double)value;

@end

NS_ASSUME_NONNULL_END
