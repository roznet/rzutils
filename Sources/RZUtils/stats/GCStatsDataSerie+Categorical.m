//
//  MyClass.m
//  
//
//  Created by Brice Rosenzweig on 21/03/2021.
//

#import "GCStatsDataSerie+Categorical.h"
#import "GCStatsDataPointCategorical.h"
#import "RZMacros.h"
@implementation GCStatsDataSerie (Categorical)

-(void)addDataPointForCategory:(NSString*)label value:(double)value addValue:(BOOL)addValue{
    GCStatsDataPointCategorical * point = [GCStatsDataPointCategorical dataPointForCategory:label andValue:value];
    NSUInteger count = self.count;
    NSUInteger idx = 0;
    for( idx = 0; idx < count; idx++){
        // Typecase because we will only use the point if it passes isSameX which means
        // it is also a categorical point
        GCStatsDataPointCategorical * one = (GCStatsDataPointCategorical*)[self dataPointAtIndex:idx];
        if( [point isSameX:one] ){
            // If match x we know one is also categorical
            if( addValue ){
                point.y_data += one.y_data;
            }// else use new value
            [self setObject:point atIndexedSubscript:idx];
            break;
        }
    }
    if( idx == count){
        // label doesn't already exist
        [self addDataPoint:point];
    }
}

-(void)addDataPointForCategory:(NSString*)label value:(double)value{
    [self addDataPointForCategory:label value:value addValue:true];
}
-(void)setDataPointForCategory:(NSString*)label value:(double)value{
    [self addDataPointForCategory:label value:value addValue:false];
}

@end
