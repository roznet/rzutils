//  MIT Licence
//
//  Created on 29/09/2012.
//
//  Copyright (c) 2012 Brice Rosenzweig.
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

@import Foundation;
#import "RZMacros.h"

typedef NS_ENUM(NSUInteger, gcUnitFormat) {
    gcUnitFormatTime,
    gcUnitFormatInteger,
    gcUnitFormatOneDigit,
    gcUnitFormatTwoDigit,
    gcUnitFormatThreeDigit,
    gcUnitFormatDouble,
};

typedef NS_ENUM(NSUInteger, gcUnitSystem) {
    gcUnitSystemDefault,
    gcUnitSystemMetric,
    gcUnitSystemImperial,
    gcUnitSystemEnd
};


typedef NS_ENUM(NSUInteger, GCUnitStrideStyle) {
    GCUnitStrideSameFoot,
    GCUnitStrideBetweenFeet,
    GCUnitStrideEnd
};

typedef NS_ENUM(NSUInteger, GCUnitSumWeightBy) {
    GCUnitSumWeightByCount,
    GCUnitSumWeightByTime,
    GCUnitSumWeightByDistance
};
NS_ASSUME_NONNULL_BEGIN;

@interface GCUnit : NSObject

@property (nonatomic,retain) NSString * key;
@property (nonatomic,retain) NSString * display;
@property (nonatomic,retain) NSString * abbr;
@property (nonatomic,retain,nullable) NSString * referenceUnitKey;
@property (nonatomic,readonly,nullable) GCUnit * referenceUnit;
@property (nonatomic,retain,nullable) GCUnit * fractionUnit;
@property (nonatomic,retain,nullable) GCUnit * compoundUnit;
@property (nonatomic,assign) gcUnitFormat format;
@property (nonatomic,assign) double scaling;
@property (nonatomic,assign) BOOL enableNumberAbbreviation;
@property (nonatomic,assign) double axisBase;
@property (nonatomic,assign) GCUnitSumWeightBy sumWeightBy;

-(instancetype)init NS_DESIGNATED_INITIALIZER;
-(GCUnit*)initWithArray:(NSArray*)aArray NS_DESIGNATED_INITIALIZER;

+(nullable GCUnit*)unitForKey:(NSString*)aKey;
+(nullable GCUnit*)unitMatchingString:(NSString*)aStr;
+(nonnull GCUnit*)unitForAny:(nonnull NSString*)any;

/**
 strideStyle can be SameFoot(2x) or BetweenFoot(1x)
 stepsPerMinute is stored as BetweenFoot
 doubleStepsPerMinute is stored as SameFoot

 */
+(GCUnitStrideStyle)strideStyle;
+(void)setStrideStyle:(GCUnitStrideStyle)style;
+(NSArray<NSString*>*)strideStyleDescriptions;

-(BOOL)betterIsMin;
-(BOOL)matchString:(NSString*)aStr;

-(BOOL)canConvertTo:(GCUnit*)otherUnit;
-(GCUnit*)commonUnit:(GCUnit*)otherUnit;
-(BOOL)isEqualToUnit:(GCUnit*)otherUnit;
-(NSArray<GCUnit*>*)compatibleUnits;

+(double)convert:(double)aN from:(NSString*)fUnitKey to:(NSString*)tUnitKey;
-(double)convertDouble:(double)aN toUnit:(GCUnit*)otherUnit;
-(double)convertDouble:(double)aN fromUnit:(GCUnit*)otherUnit;

-(double)valueToReferenceUnit:(double)aVal;
-(double)valueFromReferenceUnit:(double)aVal;

+(NSString*)format:(double)aN from:(NSString*)key to:(NSString*)tkey;
-(NSString*)formatDouble:(double)aDbl;
-(NSString*)formatDoubleNoUnits:(double)aDbl;
-(NSAttributedString*)attributedStringFor:(double)aDbl valueAttr:(NSDictionary*)vAttr unitAttr:(nullable NSDictionary*)uAttr;

-(NSArray<NSString*>*)formatComponentsForDouble:(double)aDbl;
-(NSString*)formatDouble:(double)aDbl addAbbr:(BOOL)addAbbr;

-(GCUnit*)unitForSystem:(gcUnitSystem)system;
-(GCUnit*)unitForGlobalSystem;
-(gcUnitSystem)system;
+(void)setGlobalSystem:(gcUnitSystem)system;
+(gcUnitSystem)getGlobalSystem;

-(NSComparisonResult)compare:(GCUnit*)other;

-(double)axisKnobSizeFor:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max;
-(NSArray<NSNumber*>*)axisKnobs:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max extendToKnobs:(BOOL)extend;

+(void)setCalendar:(NSCalendar*)cal;

// helpers
+(NSString*)formatBytes:(NSUInteger)bytes;
+(double)kilojoulesFromWatts:(double)watts andSeconds:(double)seconds;
+(double)wattsFromKilojoules:(double)kj andSeconds:(double)seconds;
+(double)stepsForCadence:(double)cadence andSeconds:(double)seconds;
+(double)cadenceForSteps:(double)steps andSeconds:(double)seconds;


// Easy access for units
+(GCUnit*)year;
+(GCUnit*)dateyear;
+(GCUnit*)date;
+(GCUnit*)timeofday;
+(GCUnit*)datetime;
+(GCUnit*)datemonth;
+(GCUnit*)second;
+(GCUnit*)ms;
+(GCUnit*)yearly;
+(GCUnit*)day;
+(GCUnit*)hour;
+(GCUnit*)minute;
+(GCUnit*)dateshort;
+(GCUnit*)weekly;
+(GCUnit*)monthly;
+(GCUnit*)hobbshour;
+(GCUnit*)decimalhour;

+(GCUnit*)kilocalorie;
+(GCUnit*)joule;

+(GCUnit*)centimeter;
+(GCUnit*)mile;
+(GCUnit*)yard;
+(GCUnit*)millimeter;
+(GCUnit*)inch;
+(GCUnit*)meter;
+(GCUnit*)kilometer;
+(GCUnit*)nm;

+(GCUnit*)kph;
+(GCUnit*)secpermile;
+(GCUnit*)min100m;
+(GCUnit*)sec100m;
+(GCUnit*)mps;
+(GCUnit*)minpermile;
+(GCUnit*)meterperhour;
+(GCUnit*)secperkm;
+(GCUnit*)mph;
+(GCUnit*)minperkm;
+(GCUnit*)sec100yd;
+(GCUnit*)centimetersPerMillisecond;
+(GCUnit*)feetperhour;
+(GCUnit*)hmph;

+(GCUnit*)bpm;
+(GCUnit*)dimensionless;
+(GCUnit*)percent;
+(GCUnit*)stride;
+(GCUnit*)foot;
+(GCUnit*)shots;
+(GCUnit*)stepsPerMinute;
+(GCUnit*)strokesPerMinute;
+(GCUnit*)doubleStepsPerMinute;
+(GCUnit*)rpm;
+(GCUnit*)hydph;
+(GCUnit*)sampleCount;
+(GCUnit*)cpm;
+(GCUnit*)strideyd;
+(GCUnit*)dd;
+(GCUnit*)revolution;
+(GCUnit*)kilogram;
+(GCUnit*)gram;
+(GCUnit*)pound;
+(GCUnit*)celsius;
+(GCUnit*)fahrenheit;
+(GCUnit*)semicircle;
+(GCUnit*)kilojoule;
+(GCUnit*)step;
+(GCUnit*)radian;
+(GCUnit*)strideRate;
+(GCUnit*)mpm;
+(GCUnit*)development;
+(GCUnit*)min100yd;
+(GCUnit*)cps;
+(GCUnit*)watt;
+(GCUnit*)volt;
+(GCUnit*)kilobyte;
+(GCUnit*)megabyte;
+(GCUnit*)gigabyte;
+(GCUnit*)terabyte;
+(GCUnit*)byte;
+(GCUnit*)usgallon;
+(GCUnit*)liter;
+(GCUnit*)avgasKilogram;
+(GCUnit*)avgasPound;
+(GCUnit*)knot;

+(GCUnit*)gph;
+(GCUnit*)lph;

+(GCUnit*)nmpergallon;
+(GCUnit*)milepergallon;
+(GCUnit*)kmperliter;
+(GCUnit*)literper100km;
@end


NS_ASSUME_NONNULL_END
