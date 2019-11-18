//
//  GCStatsSerieOfSerieWithUnits.m
//  RZUtils
//
//  Created by Brice Rosenzweig on 17/11/2019.
//  Copyright © 2019 Brice Rosenzweig. All rights reserved.
//

#import "GCStatsSerieOfSerieWithUnits.h"
#import "GCStatsFunctions.h"
#pragma mark - Holder


@interface GCStatsSerieOfSerieHolder : NSObject
@property (nonatomic,retain) GCNumberWithUnit * sValue;
@property (nonatomic,retain) GCStatsDataSerieWithUnit * serieWithUnit;
@property (nonatomic,retain) GCStatsInterpFunction *interpFunction;
+(GCStatsSerieOfSerieHolder*)serieOfSerieHolder:(GCNumberWithUnit*)num serie:(GCStatsDataSerieWithUnit*)serie;

-(double)valueForX:(double)x;

@end

@implementation GCStatsSerieOfSerieHolder

+(GCStatsSerieOfSerieHolder*)serieOfSerieHolder:(GCNumberWithUnit*)num serie:(GCStatsDataSerieWithUnit*)serie{
    GCStatsSerieOfSerieHolder * rv = RZReturnAutorelease([[GCStatsSerieOfSerieHolder alloc] init]);
    if( rv ){
        rv.sValue = num;
        rv.serieWithUnit = serie;
    }
    return rv;
}
#if !__has_feature(objc_arc)
-(void)dealloc{
    [_sValue release];
    [_serieWithUnit release];
    [_interpFunction release];
    
    [super dealloc];
}
#endif

-(double)valueForX:(double)x{
    if( self.interpFunction == nil){
        self.interpFunction = [GCStatsInterpFunction interpFunctionWithSerie:self.serieWithUnit.serie];
    }
    return [self.interpFunction valueForX:x];
}
@end

#pragma mark - SerieOfSerie

@interface GCStatsSerieOfSerieWithUnits ()
@property (nonatomic,retain) GCUnit * sUnit;
@property (nonatomic,retain) NSMutableArray<GCStatsSerieOfSerieHolder*>*series;
@end

@implementation GCStatsSerieOfSerieWithUnits

+(GCStatsSerieOfSerieWithUnits*)serieOfSerieWithUnits:(GCUnit*)sUnit{
    GCStatsSerieOfSerieWithUnits * rv = RZReturnAutorelease([[GCStatsSerieOfSerieWithUnits alloc] init]);
    if( rv ){
        rv.sUnit = sUnit;
        rv.series = nil;
    }
    return rv;
}

#if !__has_feature(objc_arc)
-(void)dealloc{
    [_sUnit release];
    [_series release];
    
    [super dealloc];
}
#endif

-(void)addSerie:(GCStatsDataSerieWithUnit*)serie for:(GCNumberWithUnit*)val{
    if( self.series == nil){
        self.series = [NSMutableArray array];
    };
    [self.series addObject:[GCStatsSerieOfSerieHolder serieOfSerieHolder:val serie:serie]];
    [self sortSeries];
}

-(void)addSerie:(GCStatsDataSerieWithUnit*)serie forDate:(NSDate*)date{
    if( self.series == nil){
        self.series = [NSMutableArray array];
    };
    GCNumberWithUnit * num = [GCNumberWithUnit numberWithUnit:[GCUnit date]
                                                     andValue:date.timeIntervalSinceReferenceDate];
    [self.series addObject:[GCStatsSerieOfSerieHolder serieOfSerieHolder:num
                                                                   serie:serie]];
    [self sortSeries];
}

-(void)sortSeries{
    [self.series sortUsingComparator:^NSComparisonResult(GCStatsSerieOfSerieHolder * h1, GCStatsSerieOfSerieHolder * h2){
        return [h1.sValue compare:h2.sValue];
    }];
}
-(GCStatsDataSerieWithUnit*)serieForX:(GCNumberWithUnit*)x{
    GCStatsDataSerieWithUnit * rv = [GCStatsDataSerieWithUnit dataSerieWithUnit:x.unit];
    rv.xUnit = self.sUnit;
    for (GCStatsSerieOfSerieHolder * holder in self.series) {
        rv.unit = holder.serieWithUnit.unit;
        double y = [holder valueForX:x.value];
        [rv addNumberWithUnit:[GCNumberWithUnit numberWithUnit:holder.serieWithUnit.unit andValue:y] forX:holder.sValue.value];
    }
    return rv;
}

@end
