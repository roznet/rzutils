//  MIT Licence
//
//  Created on 05/03/2016.
//
//  Copyright (c) 2016 Brice Rosenzweig.
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

#import "GCUnitLogScale.h"
#import "RZMacros.h"

NS_INLINE double FROM_LOG_SCALE(double x,double base, double shift, double scale) {
    return (pow(base, x)-shift)/scale;
}
NS_INLINE double TO_LOG_SCALE(double x,double base, double shift, double scale) {
    return log(x*scale+shift)/log(base);
}

@interface GCUnitLogScale ()
@property (nonatomic,retain) GCUnit * underlyingUnit;
@property (nonatomic,assign) double base;
@property (nonatomic,assign) double scale;
@property (nonatomic,assign) double shift;

@end


@implementation GCUnitLogScale

+(GCUnitLogScale*)logScaleUnitFor:(GCUnit*)underlying base:(double)base scaling:(double)scale shift:(double)shift{
    GCUnitLogScale * rv = RZReturnAutorelease([[GCUnitLogScale alloc] init]);
    if (rv) {
        rv.underlyingUnit = underlying;
        rv.referenceUnitKey = underlying.key;
        rv.base = base;
        rv.scale = scale;
        rv.shift = shift;
    }
    return rv;
}

#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_underlyingUnit release];
    [super dealloc];
}
#endif

-(NSString*)description{
    return [NSString stringWithFormat:@"log(%@)", self.underlyingUnit];
}

-(double)valueToReferenceUnit:(double)aVal{
    return FROM_LOG_SCALE(aVal,_base,_shift,_scale);
}

-(double)valueFromReferenceUnit:(double)aVal{
    return TO_LOG_SCALE(aVal,_base,_shift,_scale);
}

-(NSString*)formatDoubleNoUnits:(double)aDbl{
    double unitValue = FROM_LOG_SCALE(aDbl,_base,_shift,_scale);
    return [self.underlyingUnit formatDoubleNoUnits:unitValue];
}

-(NSString*)formatDouble:(double)aDbl{
    double unitValue = FROM_LOG_SCALE(aDbl,_base,_shift,_scale);
    return [self.underlyingUnit formatDouble:unitValue];
}

-(NSArray<NSNumber*>*)axisKnobs:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max extendToKnobs:(BOOL)extend{
    NSArray<NSNumber*>*starting = [super axisKnobs:nKnobs min:x_min max:x_max extendToKnobs:extend];
    
    NSMutableArray*rv = [NSMutableArray array];
    
    double attemptBase = self.axisBase != 0.0 ? self.axisBase : 100;
    
    NSArray<NSNumber*>*attempts = nil;
    if( fabs(self.underlyingUnit.axisBase - 60.0) < 1.0E-5){
        // special case for seconds
        attempts = @[ @(5), @(10), @(15), @(30), @(60), @(600), @(60*30), @(60*60)];
    }else{
        attempts = @[ @(5), @(10), @(50), @(100), @(500), @(1000), @(5000)];
    }
    
    double log_size = [self axisKnobSizeFor:nKnobs min:x_min max:x_max];

    // Now try to find the biggest "rounded" number in the underlying unit that is still
    // close enough to the exact knob in log space.
    // We define "close enough" as tolerance % of the distance between knobs in log space
    // as long as the rounded number is within 3% of the distance between knobs, we prefer that
    // to the log immplied number
    double tolerance = 3.0;
    
    for (NSNumber * one in starting) {
        double log_x = one.doubleValue;
        double x = [self.underlyingUnit convertDouble:log_x fromUnit:self];
        
        double log_best = log_x;
        double log_best_distance = 0.0;
        
        for (NSNumber * one in attempts) {
            double knob = one.doubleValue;
            double rounded = round(x/knob)*knob;
            double log_rounded = [self.underlyingUnit convertDouble:rounded toUnit:self];
            double distance = fabs(log_rounded - log_x);
            if( distance < (tolerance*log_size / 100.0) && distance > log_best_distance) {
                log_best = log_rounded;
                log_best_distance = distance;
            }
        }
        [rv addObject:@(log_best)];
    }
    
    return rv;
}
@end
