//
//  MyClass.m
//  
//
//  Created by Brice Rosenzweig on 21/03/2021.
//

#import "GCStatsDataPointCategorical.h"
#import "RZMacros.h"

@implementation GCStatsDataPointCategorical

+(GCStatsDataPointCategorical*)dataPointForCategory:(NSString*)label andValue:(double)value{
    GCStatsDataPointCategorical * rv = RZReturnAutorelease([[GCStatsDataPointCategorical alloc] init]);
    if (rv) {
        rv.x_data = 0.0;
        rv.y_data = value;
        rv.categoryLabel = label;
    }
    return rv;
}

-(BOOL)isEqual:(id)object{
    if (self==object) {
        return true;
    }else if ([object isKindOfClass:[GCStatsDataPointCategorical class]]){
        return [self isEqualToPointCategorical:object];
    }else{
        return false;
    }
}

-(NSUInteger)hash{
    return self.categoryLabel.hash + @(self.y_data).hash;
}

-(BOOL)isEqualToPointCategorical:(GCStatsDataPointCategorical*)other{
    return [other.categoryLabel isEqualToString:self.categoryLabel] && [self isEqualToPoint:other];
}

-(BOOL)isSameX:(GCStatsDataPointCategorical *)other{
    if( [other isKindOfClass:[GCStatsDataPointCategorical class] ] ){
        return [self.categoryLabel isEqualToString:other.categoryLabel];
    }
    return false;
}

@end
