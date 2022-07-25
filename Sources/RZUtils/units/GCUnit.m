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

#import "GCUnit.h"
#import "RZMacros.h"
#include <math.h>
#import "NSDictionary+RZHelper.h"
#import "GCUnitCalendarUnit.h"
#import "GCUnitDate.h"
#import "GCUnitLinear.h"
#import "GCUnitInverseLinear.h"
#import "GCUnitTimeOfDay.h"
#import "GCUnitElapsedSince.h"

#define GCUNITFORKEY(my_unit_key) +(GCUnit*)my_unit_key{ return [GCUnit unitForKey:@#my_unit_key]; }


NSMutableDictionary * _unitsRegistry = nil;
NSDictionary * _unitsMetrics = nil;
NSDictionary * _unitsImperial = nil;
gcUnitSystem globalSystem = gcUnitSystemDefault;
GCUnitStrideStyle _strideStyle = GCUnitStrideSameFoot;

//1.6093440
static const double GCUNIT_MILES = 1609.344;
static const double GCUNIT_POUND = 0.45359237;
static const double GCUNIT_FOOT = 1./3.2808399;
static const double GCUNIT_YARD = 0.9144;
static const double GCUNIT_INCHES = 1./39.3700787;
static const double GCUNIT_JOULES = 1./4.184;// in kcal

static const double EPS = 1.e-10;

void buildUnitSystemCache(){
    if (_unitsImperial == nil) {

        _unitsMetrics = @{
                          @"yard"       : @"meter",
                          @"foot"       : @"meter",
                          @"mile"       : @"kilometer",
                          @"minpermile" : @"minperkm",
                          @"mph"        : @"kph",
                          @"fahrenheit" : @"celsius",
                          @"min100yd"   : @"min100m",
                          @"hydph"      : @"hmph",
                          @"strideyd"   : @"stride",
                          @"pound"      : @"kilogram",
                          @"feetperhour": @"meterperhour",
                          @"footelevation": @"meterelevation",
                          };

        // Meter -> yard or foot ambiguous, default should be yard
        NSMutableDictionary * tempImperial = [NSMutableDictionary dictionaryWithDictionary:[_unitsMetrics dictionarySwappingKeysForObjects]];
        tempImperial[@"meter"] = @"yard";
        tempImperial[@"celsius"] = @"fahrenheit";
        _unitsImperial = [NSDictionary dictionaryWithDictionary:tempImperial];
        RZRetain(_unitsMetrics);
        RZRetain(_unitsImperial);
    }
}

void registerDouble( NSArray * defs){
    GCUnit * unit = RZReturnAutorelease([[GCUnit alloc] initWithArray:defs]);
    unit.format = gcUnitFormatDouble;
    _unitsRegistry[defs[0]] = unit;
}


void registerSimple( NSArray * defs){
    GCUnit * unit = RZReturnAutorelease([[GCUnit alloc] initWithArray:defs]);
    unit.format = gcUnitFormatTwoDigit;
    unit.referenceUnitKey = unit.key;  // make sure can convert to itself...
    _unitsRegistry[defs[0]] = unit;
}

void registerSimpl0( NSArray * defs){
    GCUnit * unit = RZReturnAutorelease([[GCUnit alloc] initWithArray:defs]);
    unit.format = gcUnitFormatInteger;
    unit.referenceUnitKey = unit.key;  // make sure can convert to itself...
    _unitsRegistry[defs[0]] = unit;
}

void registerSimpl1( NSArray * defs){
    GCUnit * unit = RZReturnAutorelease([[GCUnit alloc] initWithArray:defs]);
    unit.format = gcUnitFormatOneDigit;
    unit.referenceUnitKey = unit.key;  // make sure can convert to itself...
    _unitsRegistry[defs[0]] = unit;
}
void registerSimpl3( NSArray * defs){
    GCUnit * unit = RZReturnAutorelease([[GCUnit alloc] initWithArray:defs]);
    unit.format = gcUnitFormatThreeDigit;
    unit.referenceUnitKey = unit.key;  // make sure can convert to itself...
    _unitsRegistry[defs[0]] = unit;
}

void registerLinear( NSArray * defs, NSString * ref, double m, double o){
    GCUnitLinear * unit = [GCUnitLinear unitLinearWithArray:defs reference:ref multiplier:m andOffset:o];
    unit.format = gcUnitFormatTwoDigit;
    _unitsRegistry[defs[0]] = unit;
}

void registerLinea1( NSArray * defs, NSString * ref, double m, double o){
    GCUnitLinear * unit = [GCUnitLinear unitLinearWithArray:defs reference:ref multiplier:m andOffset:o];
    unit.format = gcUnitFormatOneDigit;
    _unitsRegistry[defs[0]] = unit;
}

void registerLinea2( NSArray * defs, NSString * ref, double m, double o){
    GCUnitLinear * unit = [GCUnitLinear unitLinearWithArray:defs reference:ref multiplier:m andOffset:o];
    unit.format = gcUnitFormatTwoDigit;
    _unitsRegistry[defs[0]] = unit;
}

void registerLinea0( NSArray * defs, NSString * ref, double m, double o){
    GCUnitLinear * unit = [GCUnitLinear unitLinearWithArray:defs reference:ref multiplier:m andOffset:o];
    unit.format = gcUnitFormatInteger;
    _unitsRegistry[defs[0]] = unit;
}

void registerLinTim( NSArray * defs, NSString * ref, double m, double o){
    GCUnitLinear * unit = [GCUnitLinear unitLinearWithArray:defs reference:ref multiplier:m andOffset:o];
    unit.format = gcUnitFormatTime;
    _unitsRegistry[defs[0]] = unit;
}

void registerInvLin( NSArray * defs, NSString * ref, double m, double o){
    GCUnitInverseLinear * unit = [GCUnitInverseLinear unitInverseLinearWithArray:defs reference:ref multiplier:m andOffset:o];
    unit.format = gcUnitFormatTime;
    _unitsRegistry[defs[0]] = unit;
}
void registerDaCa( NSString * name, NSDateFormatterStyle dateStyle, NSDateFormatterStyle timeStyle, NSString * fmt, NSCalendarUnit cal){
    GCUnitDate * unit = [[GCUnitDate alloc] init];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    unit.key = name;
    unit.abbr = @"";
    unit.display = @"";

    if (fmt) {
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = fmt;
    }else{
        formatter.dateStyle = dateStyle;
        formatter.timeStyle = timeStyle;
    }
    unit.dateFormatter = formatter;
    unit.useCalendarUnit = true;
    unit.calendarUnit = cal;

    _unitsRegistry[name] = unit;
    RZRelease(unit);
    RZRelease(formatter);
}
void registerDate( NSString * name, NSDateFormatterStyle dateStyle, NSDateFormatterStyle timeStyle, NSString * fmt){
    GCUnitDate * unit = [[GCUnitDate alloc] init];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    unit.key = name;
    unit.abbr = @"";
    unit.display = @"";

    if (fmt) {
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = fmt;
    }else{
        formatter.dateStyle = dateStyle;
        formatter.timeStyle = timeStyle;
    }
    unit.dateFormatter = formatter;

    _unitsRegistry[name] = unit;
    RZRelease(unit);
    RZRelease(formatter);
}

void registerTofD(NSString * name){
    GCUnitTimeOfDay * unit = [[GCUnitTimeOfDay alloc] init];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];

    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    unit.dateFormatter = formatter;
    unit.key = name;
    unit.abbr = @"";
    unit.display = @"";

    _unitsRegistry[name] = unit;
    RZRelease(unit);
    RZRelease(formatter);
}

void registerCalUnit( NSString * name, NSCalendarUnit calUnit){
    GCUnitCalendarUnit * unit = [GCUnitCalendarUnit calendarUnit:calUnit calendar:nil referenceDate:nil];

    _unitsRegistry[name] = unit;
}

#pragma mark

void registerUnits(){
    if (!_unitsRegistry) {
        _unitsRegistry = RZReturnRetain([NSMutableDictionary dictionaryWithCapacity:60]);
        //simple
        BOOL allUnitSet = true;

        if (allUnitSet) {
            registerSimple( @[ @"revolution", @"Revolutions", @"rev"]);
            registerSimple( @[ @"numberOfActivities", @"Activities", @"Activities"]);
            registerSimple( @[ @"sampleCount", @"Samples", @"Samples"]);

            registerSimple( @[ @"ml/kg/min", @"ml/kg/min", @"ml/kg/min"]);
            registerSimple( @[ @"volt", @"Volt", @""]);
            registerSimpl0( @[ @"watt", @"Watts", @"W"]);
            registerSimple( @[ @"kN/m", @"kN/m", @"kN/m"]);

            registerSimpl0( @[ @"strokesPerMinute", @"strokes/min", @"strokes/min"]);

            registerSimple( @[ @"c/Hr", @"c/Hr", @"c/Hr"]); // Energy Expenditure
            
            registerLinea0( @[ @"kilocalorie", @"Calories", @"C"], @"kilocalorie", 1., 0. );
            registerLinear( @[ @"kilojoule", @"Kilojoule", @"kj"], @"kilocalorie", GCUNIT_JOULES, 0.);
            registerLinear( @[ @"joule", @"joule", @"J"], @"kilocalorie", GCUNIT_JOULES/1000., 0.);

            registerSimpl0( @[ @"rpm", @"Revolutions per Minute", @"rpm"]);
            registerSimple( @[ @"te", @"Training Effect", @""]);
            registerSimpl3( @[ @"if", @"Intensity Factor", @""]);
            registerSimpl3( @[ @"kg/N", @"Running Efficiency", @"kg/N"]);
            
            registerLinea0(@[ @"hPA", @"hPA", @"hPA"],   @"hPA", 1., 0.);
            registerLinea2(@[ @"inHg", @"inHg", @"inHg"], @"hPA", 33.77, 0.);
            
            
            
        }
        registerSimple( @[ @"percent", @"Percent", @"%"]);
        registerSimpl0( @[ @"dimensionless", @"Dimensionless", @""]);

        registerSimpl0( @[ @"step", @"Steps", @"s"]);
        registerLinea0( @[ @"stepsPerMinute", @"Steps per Minute", @"spm"], @"stepsPerMinute", 1., 0.);
        registerLinea0( @[ @"doubleStepsPerMinute", @"Steps per Minute", @"spm"], @"stepsPerMinute", 0.5, 0.);
        registerSimple( @[ @"strideRate", @"Stride rate", @"Stride rate"]);

        registerSimple( @[ @"year", @"Year", @""]);
        registerSimple( @[ @"day", @"Days", @"d"]);

        registerSimpl0( @[ @"bpm", @"Beats per Minute", @"bpm"]);

        //angle
        if (allUnitSet) {
            registerLinea0( @[ @"radian", @"Radian", @"rad"],       @"radian", 1.,        0.);
            registerLinea0( @[ @"dd", @"Decimal Degrees", @"dd"],   @"radian", M_PI/180., 0.);
            registerLinea0( @[ @"semicircle", @"Semicircle", @"sc"],@"radian", M_PI/2147483648.,0.);
        }

        //time
        registerLinTim( @[ @"ms",     @"Milliseconds",@"ms"   ],          @"second", 1./1000., 0.);
        registerLinTim( @[ @"second", @"Seconds",     @""     ],          @"second", 1.,       0.);
        registerLinTim( @[ @"minute", @"Minutes",     @"",    @"second"], @"second", 60.,      0.);
        registerLinTim( @[ @"hour",   @"Hours",       @"",    @"minute"], @"second", 3600.,    0.);
        //time for flying/aviation
        registerLinTim( @[ @"hobbsminute", @"Minutes",     @"",    ], @"second", 60.,      0.);
        registerLinTim( @[ @"hobbshour",   @"Hours",       @"",   @"hobbsminute" ], @"second", 3600.,    0.);
        registerLinea1( @[ @"decimalhour",   @"Hours",       @"",    ], @"second", 3600.,    0.);
        
        //speed
        registerLinear( @[ @"mps",        @"Meters per Second",   @"mps"  ],                 @"mps", 1.0,                 0.);
        registerLinear( @[ @"kph",        @"Kilometers per Hour", @"km/h" ],                 @"mps", 1000./3600.,         0.);
        registerLinear( @[ @"mph",        @"Miles per Hour",      @"mph"  ],                 @"mps", GCUNIT_MILES/3600.,  0.);
        registerLinear( @[ @"knot",         @"Knots",               @"kt"  ],                  @"mps", 1852.0/3600.,        0.);
        registerInvLin( @[ @"secperkm",   @"Seconds per Kilometer",@"sec/km"],               @"mps", 1000.,               0.);
        registerInvLin( @[ @"minperkm",   @"Minutes per Kilometer",@"min/km", @"secperkm"],  @"mps", 60./3600.*1000.,     0.);
        registerInvLin( @[ @"secpermile", @"Seconds per Mile",    @"sec/mi" ],               @"mps", GCUNIT_MILES,        0.);
        registerInvLin( @[ @"minpermile", @"Minutes per Mile",    @"min/mi",  @"secpermile"],@"mps", 60./3600.*GCUNIT_MILES,0.);

        registerInvLin( @[ @"sec100yd",   @"sec/100 yd",          @"sec/100 yd"],              @"mps", 100.*GCUNIT_YARD,   0.);
        registerInvLin( @[ @"sec100m",    @"sec/100 m",           @"sec/100 m" ],              @"mps", 100.,               0.);
        registerInvLin( @[ @"min100m",    @"min/100 m",           @"min/100 m",  @"sec100m"],  @"mps", 60./3600.*100.,     0.);
        registerInvLin( @[ @"min100yd",   @"min/100 yd",          @"min/100 yd", @"sec100yd"], @"mps", 60./3600.*100.*GCUNIT_YARD,0.);
        registerLinea1( @[ @"hmph",       @"100m/hour",           @"100m/hour"],               @"mps", 100./3600.,         0.);
        registerLinea1( @[ @"hydph",      @"100yd/hour",          @"100yd/hour"],              @"mps", 100./3600.*GCUNIT_YARD,0.);

        // Ascent speed
        registerLinea1( @[ @"meterperhour", @"Meters per hour",   @"m/h"  ],                @"mps", 1.0/3600.,               0.);
        registerLinea1( @[ @"feetperhour", @"Feet per hour",   @"ft/h"  ],                @"mps", GCUNIT_FOOT/3600.,         0.);
        registerLinea1( @[ @"feetperminute", @"Feet per minute",   @"fpm"  ],                @"mps", GCUNIT_FOOT/60.,         0.);

        if (allUnitSet) {
            registerSimple( @[ @"mpm",        @"Meters per Minute",   @"mpm"]);
            registerSimple( @[ @"cpm",        @"Centimeters per Minute", @"cpm"]);
            registerSimple( @[ @"cps",        @"Centimeters per Second", @"cps"]);
            registerLinear(@[ @"centimetersPerMillisecond", @"Centimeters per Millisecond", @"cm/ms"], @"mps", 10., 0.);
        }

        //distance
        registerLinear( @[ @"development",@"Development",@"m"],  @"meter", 1.0,           0.0);
        registerLinear( @[ @"stride",    @"Stride",     @"m" ],  @"meter", 1.0,           0.0);
        registerLinear( @[ @"strideyd",  @"Strideyd",   @"yd"],  @"meter", GCUNIT_YARD,   0.0);
        registerLinea0( @[ @"meter",     @"Meters",     @"m" ],  @"meter", 1.0,           0.0);
        registerLinear( @[ @"mile",      @"Miles",      @"mi"],  @"meter", GCUNIT_MILES,  0.0);
        registerLinear( @[ @"kilometer", @"Kilometers", @"km"],  @"meter", 1000.,         0.0);
        registerLinear( @[ @"foot",      @"Feet",       @"ft"],  @"meter", GCUNIT_FOOT,   0.0);
        registerLinear( @[ @"yard",      @"Yards",      @"yd"],  @"meter", GCUNIT_YARD,   0.0);
        registerLinear( @[ @"inch",      @"Inches",     @"in"],  @"meter", GCUNIT_INCHES, 0.0);
        registerLinear( @[ @"nm",      @"Nautical Miles",     @"nm"],  @"meter", 1852.0, 0.0);
        registerLinea1( @[ @"centimeter",@"Centimeters",@"cm"],  @"meter", 0.01,          0.0);
        registerLinea1( @[ @"millimeter",@"Millimeter",@"mm"],   @"meter", 0.001,         0.0);
        registerLinea0( @[ @"floor",     @"Floor",      @"floors"],    @"meter", 3.0,           0.0);
        // special meterelevation that will not have coumpounding
        registerLinea0( @[ @"meterelevation",@"Meters (Elev.)",     @"m" ],  @"meter", 1.0,           0.0);
        registerLinear( @[ @"footelevation", @"Feet (Elev.)",       @"ft"],  @"meter", GCUNIT_FOOT,   0.0);

        //mass
        registerLinear( @[ @"kilogram", @"Kilograms", @"kg"],  @"kilogram", 1.0, 0.0);
        registerLinear( @[ @"pound",    @"Pounds",    @"lbs"], @"kilogram", GCUNIT_POUND, 0.0);
        registerLinear( @[ @"gram",     @"Gram",      @""],    @"kilogram", 0.001, 0.0);

        // temperature
        registerLinea0( @[ @"celsius",    @"°Celsius",    @"°C"], @"celsius", 1.,        0.0);
        registerLinea0( @[ @"celcius",    @"° Celsius",    @"°C "], @"celsius", 1.,        0.0);
        registerLinea0( @[ @"fahrenheit", @"°Fahrenheit", @"°F"], @"celsius", 5./9.,     -32.*5./9.);

        // dates
        registerDate(@"date",      NSDateFormatterMediumStyle, NSDateFormatterNoStyle, nil);
        registerDate(@"dateshort", NSDateFormatterShortStyle,  NSDateFormatterNoStyle, nil);
        registerDate(@"datetime",  NSDateFormatterShortStyle, NSDateFormatterMediumStyle, nil);
        registerDaCa(@"datemonth", NSDateFormatterNoStyle,     NSDateFormatterNoStyle, @"MMM yy", NSCalendarUnitMonth);
        registerDaCa(@"dateyear", NSDateFormatterNoStyle,     NSDateFormatterNoStyle, @"yyyy",    NSCalendarUnitYear);

        // volumes
        registerLinear( @[ @"liter", @"liter", @"l"],  @"liter", 1.0, 0.0);
        registerLinear( @[ @"usgallon", @"US Gallon", @"gal"],  @"liter", 3.785411784, 0.0);
        registerLinear( @[ @"avgasKilogram", @"Avgas Kilogram", @"kg"],  @"liter", 1.0/0.71, 0.0);
        registerLinear( @[ @"avgasPound", @"Avgas Pound", @"lbs"],  @"liter", GCUNIT_POUND / 0.71, 0.0);
        registerLinear( @[ @"gph", @"Gallon/hour", @"gph"], @"lph", 3.785411784, 0.0);
        registerLinear( @[ @"lph", @"liter/hour", @"lph"], @"lph", 1.0, 0.0);

        
        registerTofD(@"timeofday");

        registerCalUnit(@"weekly", NSCalendarUnitWeekOfYear);
        registerCalUnit(@"monthly", NSCalendarUnitMonth);
        registerCalUnit(@"yearly", NSCalendarUnitYear);

        if (allUnitSet) {
            //storage
            registerSimple( @[ @"byte",     @"bytes",     @"b"]);
            registerSimple( @[ @"megabyte", @"megabytes", @"Mb"]);
            registerSimple( @[ @"terabyte", @"terrabytes",@"tb"]);
            registerSimple( @[ @"kilobyte", @"kilobytes", @"kb"]);
            registerSimple( @[ @"gigabyte", @"gigabytes", @"gb"]);

            // tennis
            registerSimpl0( @[ @"shots", @"shots", @"shots" ] );
        }

        // need both registered, so do after initial register;
        [_unitsRegistry[@"hobbsminute"] setCompoundUnit:_unitsRegistry[@"hobbshour"]];
        [_unitsRegistry[@"minute"] setCompoundUnit:_unitsRegistry[@"hour"]];
        [_unitsRegistry[@"second"] setCompoundUnit:_unitsRegistry[@"minute"]];
        [_unitsRegistry[@"meter"]  setCompoundUnit:_unitsRegistry[@"kilometer"]];
        [_unitsRegistry[@"yard"]   setCompoundUnit:_unitsRegistry[@"mile"]];
        [_unitsRegistry[@"centimeter"]   setCompoundUnit:_unitsRegistry[@"meter"]];
        [_unitsRegistry[@"second"] setAxisBase:60.];
        [_unitsRegistry[@"minperkm"] setAxisBase:1./60.];
        [_unitsRegistry[@"minpermile"] setAxisBase:1./60.];

        [_unitsRegistry[@"step"] setEnableNumberAbbreviation:true];

        // Fill in the proper weighting when doing sum
        GCUnit * speed = _unitsRegistry[@"mps"];
        GCUnit * bpm = _unitsRegistry[@"bpm"];
        GCUnit * spm = _unitsRegistry[@"stepsPerMinute"];
        GCUnit * rpm = _unitsRegistry[@"rpm"];

        for (GCUnit * unit in _unitsRegistry.allValues) {
            unit.sumWeightBy = GCUnitSumWeightByCount;

            if( [unit canConvertTo:speed]){
                if( unit.betterIsMin ){
                    unit.sumWeightBy = GCUnitSumWeightByDistance;
                }else{
                    unit.sumWeightBy = GCUnitSumWeightByTime;
                }
            }
            if( [unit canConvertTo:bpm] || [unit canConvertTo:spm] || [unit canConvertTo:rpm]){
                unit.sumWeightBy = GCUnitSumWeightByTime;
            }
        }
    }
}


@implementation GCUnit

#if !__has_feature(objc_arc)
-(void)dealloc{
    [_key release];
    [_display release];
    [_abbr release];
    [_fractionUnit release];
    [_compoundUnit release];
    [_referenceUnitKey release];

    [super dealloc];
}
#endif

-(instancetype)init{
    return [super init];
}

-(GCUnit*)initWithArray:(NSArray*)aArray{
    self = [super init];
    if (self) {
        self.key = aArray[0];
        self.display = aArray[1];
        self.abbr = aArray[2];
        self.axisBase = 1.;
        if (aArray.count > 3) {
            self.fractionUnit = [GCUnit unitForKey:aArray[3]];
            _format = gcUnitFormatTime;
        }else{
            _fractionUnit = nil;
        }
        if (aArray.count > 4) {
            self.compoundUnit = [GCUnit unitForKey:aArray[4]];
            _format = gcUnitFormatTime;
        }else{
            _compoundUnit = nil;
        }
    }
    return self;
}


#pragma mark - Description and debug

-(NSString*)description{
    return _key;
}
-(NSString*)debugDescription{
    return _key;
}
#pragma mark - Comparison

-(NSComparisonResult)compare:(GCUnit*)other{
    return [self.key compare:other.key];
}
-(BOOL)isEqualToUnit:(GCUnit*)otherUnit{
    return [self.key isEqualToString:otherUnit.key];
}
- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [_key isEqualToString:[other key]];
}
-(NSUInteger)hash{
    return [_key hash];
}

#pragma mark - Axis



-(double)axisKnobSizeFor:(NSUInteger)n min:(double)x_min max:(double)x_max{
    double range = (x_max - x_min);

    // default
    if (n<2 || fabs(range)<1.e-12) {
        return 0.;
    }
    // we know n > 0 now
    double rv = range/n;

    if(self.axisBase != 0.){

        double count = n-1.;
        double base = self.axisBase;

        double unrounded = range/count/base;
        double x = ceil(log10(unrounded)-1.);

        double pow10x = pow(10., x);
        double roundedRange = unrounded/pow10x;

        if (roundedRange < 1.5) {
            roundedRange = 1.;
        }else if (roundedRange < 3){
            roundedRange = 2.;
        }else if (roundedRange < 7) {
            roundedRange = 5.;
        }else{
            roundedRange = 10.;
        }

        rv = roundedRange*base*pow10x;
    }else{
        double count = n-1.;
        double unrounded = range/count;
        double x = ceil(log10(unrounded)-1.);

        double pow10x = pow(10., x);
        double roundedRange = ceil(unrounded/pow10x)*pow10x;
        rv = roundedRange;
    }
    
    // Try to widen when range is zero
    if (fabs(rv)<EPS) {
        rv = x_min/2.;
        x_min /= 2.;
        if (fabs(rv)<EPS) {
            // if still 0, use arbitrary size, protect divition by 0
            rv = 1.;
        }
    }
    return rv;
}

-(NSArray*)axisKnobs:(NSUInteger)nKnobs min:(double)x_min_input max:(double)x_max extendToKnobs:(BOOL)extend{

    double x_min = x_min_input;

    NSUInteger x_nKnobs = MIN(nKnobs, 100U);

    double x_knobSize = [self axisKnobSizeFor:nKnobs min:x_min max:x_max];

    double x_knob_min = floor(x_min/x_knobSize)*x_knobSize;
    double x_knob_max = x_knob_min;
    NSMutableArray * rv = [NSMutableArray arrayWithCapacity:x_nKnobs];

    while ((x_knob_min + x_knobSize * x_nKnobs) < x_max) {
        x_nKnobs++;
    }
    [rv addObject:@(extend ? x_knob_min : x_min)];
    for (NSUInteger idx=0; idx<x_nKnobs; idx++) {
        x_knob_max += x_knobSize;
        if (x_knob_max > x_max) {
            [rv addObject:@(extend ? x_knob_max : x_max)];
            break;
        }else{
            [rv addObject:@(x_knob_max)];
        }
    }
    return rv;
}

#pragma mark - Access

-(GCUnit*)referenceUnit{
    return self.referenceUnitKey ? [GCUnit unitForKey:self.referenceUnitKey] : nil;
}

+(GCUnit*)unitForKey:(NSString *)aKey{
    if (!_unitsRegistry) {
        registerUnits();
    }
    return aKey ? _unitsRegistry[aKey] : nil;
}

+(nonnull GCUnit*)unitForAny:(nonnull NSString*)aKey{
    if (!_unitsRegistry) {
        registerUnits();
    }
    GCUnit * exist = _unitsRegistry[aKey];
    if( ! exist ){
        registerSimple( @[ aKey, aKey, aKey]);
        exist = _unitsRegistry[aKey];
    }
    return exist;
}
-(BOOL)matchString:(NSString*)aStr{
    return [_abbr isEqualToString:aStr] || [_key isEqualToString:aStr] || [_display isEqualToString:aStr];
}

+(GCUnit*)unitMatchingString:(NSString*)aStr{
    if(!_unitsRegistry){
        registerUnits();
    }

    GCUnit * rv = nil;
    for (NSString * key in _unitsRegistry) {
        GCUnit * one = _unitsRegistry[key];
        if ([one matchString:aStr]) {
            rv= one;
            break;
        }
    }
    // few special cases
    if (!rv) {
        if ([aStr isEqualToString:@"\U00002103"]) {
            rv = [GCUnit unitForKey:@"celsius"];
        }else if ([aStr isEqualToString:@"\U00002109"]){
            rv = [GCUnit unitForKey:@"fahrenheit"];
        }
    }
    return rv;
}

#pragma mark - Conversions

+(double)convert:(double)aN from:(NSString*)fUnitKey to:(NSString*)tUnitKey{
    GCUnit * from = [GCUnit unitForKey:fUnitKey];
    GCUnit * to   = [GCUnit unitForKey:tUnitKey];

    return [from convertDouble:aN toUnit:to];
}


-(BOOL)canConvertTo:(GCUnit*)otherUnit{
    return _referenceUnitKey != nil && otherUnit.referenceUnitKey && [otherUnit.referenceUnitKey isEqualToString:_referenceUnitKey];
}
-(NSArray<GCUnit*>*)compatibleUnits{
    if (!_unitsRegistry) {
        registerUnits();
    }
    NSMutableArray<GCUnit*>*rv = [NSMutableArray arrayWithObject:self];
    for (NSString * key in _unitsRegistry) {
        GCUnit * other = _unitsRegistry[key];
        if( [other.referenceUnitKey isEqualToString:self.referenceUnitKey] && ![other.key isEqualToString:self.key]){
            [rv addObject:other];
        }
    }
    return rv;
}

-(GCUnit*)commonUnit:(GCUnit*)otherUnit{
    GCUnit * rv = self;
    if (_referenceUnitKey != nil && otherUnit.referenceUnitKey && [otherUnit.referenceUnitKey isEqualToString:_referenceUnitKey]) {
        double thisInv = [self isKindOfClass:[GCUnitInverseLinear class]] ? -1. : 1.;
        double otherInv= [otherUnit isKindOfClass:[GCUnitInverseLinear class]] ? -1. : 1.;

        double thisV = [self valueToReferenceUnit:1.];
        double otherV= [otherUnit valueToReferenceUnit:1.];

        // avoid mps
        if ([self.key isEqualToString:@"mps"]) {
            thisV = 0.00001;
        }
        if ([otherUnit.key isEqualToString:@"mps"]) {
            otherV = 0.00001;
        }

        // same type: take biggest
        if (thisInv*otherInv == 1.) {
            if (otherV > thisV) {
                rv = otherUnit;
            }
        }else{ // different, favor non inverted one
            if (otherV*otherInv > thisV*thisInv) {
                rv = otherUnit;
            }
        }
    }
    return rv;
}

-(double)convertDouble:(double)aN toUnit:(GCUnit*)otherUnit{
    // cheap optimization
    if (self == otherUnit) {
        return aN;
    }

    if ([self canConvertTo:otherUnit]) {
        return [otherUnit valueFromReferenceUnit:[self valueToReferenceUnit:aN]];
    }
    return aN;
}
-(double)convertDouble:(double)aN fromUnit:(GCUnit*)otherUnit{
    // cheap optimization
    if (self == otherUnit) {
        return aN;
    }
    if ([self canConvertTo:otherUnit]) {
        return [self valueFromReferenceUnit:[otherUnit valueToReferenceUnit:aN]];
    }
    return aN;
}

-(double)valueToReferenceUnit:(double)aValue{
    return aValue;
}
-(double)valueFromReferenceUnit:(double)aValue{
    return aValue;
}

#pragma mark - Format

+(NSString*)format:(double)aN from:(NSString*)key to:(NSString*)tkey{
    double val = aN;
    if (key != nil) {
        val= [GCUnit convert:aN from:key to:tkey];
    }
    return [[GCUnit unitForKey:tkey] formatDouble:val];
}

-(NSString*)formatDouble:(double)aDbl addAbbr:(BOOL)addAbbr{
    NSArray * comp = [self formatComponentsForDouble:aDbl];
    if (addAbbr) {
        return [comp componentsJoinedByString:@" "];
    }else{
        if (comp.count==0) {
            return @"ERROR";
        }else{
            return comp[0];
        }
    }
}

-(NSArray*)formatComponentsForDouble:(double)aDbl{
    NSNumberFormatter * formatter = nil;

    double toFormat = aDbl;
    if (self.scaling!=0.) {
        toFormat *= self.scaling;
    }
    double fraction = 0.;

    NSString * fmt = nil;
    //isTimeFormat ? @"%02.0f" : @"%.2f";
    switch (_format) {
        case gcUnitFormatOneDigit:
            fmt = @"%.1f";
            break;
        case gcUnitFormatThreeDigit:
            fmt = @"%.3f";
            break;
        case gcUnitFormatTwoDigit:
            fmt = @"%.2f";
            if (log10(toFormat)>=1.1) {
                fmt = @"%.1f";
            }
            break;
        case gcUnitFormatInteger:
            fmt = @"%.0f";
            break;
        case gcUnitFormatTime:
            fmt = @"%02.0f";
            break;
        case gcUnitFormatDouble:
            fmt = @"%f";
            break;
    }
    if (_compoundUnit) {
        double cval = [_compoundUnit convertDouble:aDbl fromUnit:self];
        if (fabs( cval ) > 1) {
            return [_compoundUnit formatComponentsForDouble:cval];
        }
    }

    NSArray * fractComponents = nil;

    if (_fractionUnit) {
        // Negative number, use ceiling and fraction should be abs as sign only handled for first one
        toFormat = toFormat > 0 ? floor(toFormat) : ceil(toFormat);
        fraction = fabs(aDbl-toFormat);
        if (_format == gcUnitFormatTime) {
            fmt = @"%02.0f";
        }else{
            fmt = @"%.0f";
        }
        double fractVal = [_fractionUnit convertDouble:fraction fromUnit:self];
        if ([_fractionUnit convertDouble:round(fractVal) toUnit:self] > (1.-EPS)) {
            // edge case, fraction is closer to next unit.
            fractVal = 0.;
            toFormat += 1.;
        }
        fractComponents = [_fractionUnit formatComponentsForDouble:fractVal];
    }

    if (toFormat >= 1000.) {
        if (self.enableNumberAbbreviation) {
            if (toFormat >= 100000.) {
                fmt = [NSString stringWithFormat:@"%@k", fmt];
                toFormat /= 1000.;
            }else{
                formatter = RZReturnAutorelease([[NSNumberFormatter alloc] init]);
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                formatter.maximumFractionDigits = 0;
            }
        }else{
            formatter = RZReturnAutorelease([[NSNumberFormatter alloc] init]);
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.maximumFractionDigits = 0;
        }
    }

    NSMutableString * rv_val = formatter ? [NSMutableString stringWithString:[formatter stringFromNumber:@(toFormat)]]
                                         : [NSMutableString stringWithFormat:fmt, toFormat];

    NSMutableArray * rv = [NSMutableArray arrayWithObject:rv_val];

    if (_fractionUnit) {
        if (_format == gcUnitFormatTime) {
            [rv_val appendString:@":"];
            [rv_val appendString:fractComponents[0]];
            if (_abbr.length > 0) {
                [rv addObject:_abbr];
            }
        }else{
            [rv addObject:_abbr];
            [rv addObjectsFromArray:fractComponents];
        }
    }else{
        if (_abbr.length > 0) {
            [rv addObject:_abbr];
        }
    }

    return rv;
}

-(NSAttributedString*)attributedStringFor:(double)aDbl valueAttr:(NSDictionary*)vAttr unitAttr:(NSDictionary*)uAttr{
    NSMutableAttributedString * rv = RZReturnAutorelease([[NSMutableAttributedString alloc] init]);
    NSArray * comp = [self formatComponentsForDouble:aDbl];
    NSUInteger done = 0;
    for (NSUInteger i=0; i<comp.count; i++) {
        NSAttributedString * next = nil;
        if (i%2==0) {
            next = RZReturnAutorelease([[NSAttributedString alloc] initWithString:comp[i] attributes:vAttr]);
        }else{
            if (uAttr) {
                next = RZReturnAutorelease([[NSAttributedString alloc] initWithString:comp[i] attributes:uAttr]);
            }
        }
        if (next) {
            if (done>0) {
                NSAttributedString * space = [[NSAttributedString alloc] initWithString:@" " attributes:uAttr?: vAttr];
                [rv appendAttributedString:space];
                RZRelease(space);
            }
            done++;
            [rv appendAttributedString:next];
        }
    }
    return rv;
}


-(NSString*)formatDouble:(double)aDbl{
    return [self formatDouble:aDbl addAbbr:true];
}

-(NSString*)formatDoubleNoUnits:(double)aDbl{
    return [self formatDouble:aDbl addAbbr:false];
}

#pragma mark - Unit Systems

-(GCUnit*)unitForSystem:(gcUnitSystem)system{
    if (_unitsImperial == nil) {
        buildUnitSystemCache();
    }
    NSString * converted = nil;
    switch (system) {
        case gcUnitSystemImperial:
            converted = _unitsImperial[_key];
            break;
        case gcUnitSystemMetric:
            converted = _unitsMetrics[_key];
            break;
        default:
            break;
    }

    return converted ? [GCUnit unitForKey:converted] : self;
}

-(gcUnitSystem)system{
    if (_unitsImperial == nil) {
        buildUnitSystemCache();
    }
    // Dictionary are equivalent unit, so if exist it means it's the
    // other system..
    if (_unitsImperial[_key] ) {
        return gcUnitSystemMetric;
    }else if (_unitsMetrics[_key]){
        return gcUnitSystemImperial;
    }else{
        return gcUnitSystemDefault;
    }
}

-(GCUnit*)unitForGlobalSystem{
    return [self unitForSystem:globalSystem];
}
+(void)setGlobalSystem:(gcUnitSystem)system{
    globalSystem = system;
}
+(gcUnitSystem)getGlobalSystem{
    return globalSystem;
}
#pragma mark - Configuration

+(void)setCalendar:(NSCalendar*)cal{
    for (NSString * key in @[@"datemonth",@"dateyear",@"weekly",@"monthly",@"yearly",@"timeofday"]) {
        id unit = [GCUnit unitForKey:key];
        if ([unit respondsToSelector:@selector(setCalendar:)]) {
            [unit setCalendar:cal];
        }
    }
}


+(NSArray*)strideStyleDescriptions{
    return @[NSLocalizedString(@"Same Foot",     @"Stride Style"),
             NSLocalizedString(@"Between Feet",  @"Stride Style")
             ];
}
+(void)setStrideStyle:(GCUnitStrideStyle)style{
    if (!_unitsRegistry) {
        registerUnits();
    }

    if (style < GCUnitStrideEnd) {
        double scaleStride[GCUnitStrideEnd] = { 1., 0.5 };
        double scaleSteps[GCUnitStrideEnd]  = { 1., 2.  };
        double scaleDoubleSteps[GCUnitStrideEnd]  = { 0.5, 1.  };

        GCUnit * stride      = _unitsRegistry[@"stride"];
        GCUnit * strideyd    = _unitsRegistry[@"strideyd"];
        GCUnit * steps       = _unitsRegistry[@"stepsPerMinute"];
        GCUnit * doublesteps = _unitsRegistry[@"doubleStepsPerMinute"];

        stride.scaling = scaleStride[style];
        strideyd.scaling = scaleStride[style];
        steps.scaling = scaleSteps[style];
        doublesteps.scaling = scaleDoubleSteps[style];
    }
}
+(GCUnitStrideStyle)strideStyle{
    return _strideStyle;
}
-(BOOL)betterIsMin{
    return false;
}

#pragma mark - Convenience

+(NSString*)formatBytes:(NSUInteger)bytes{
    NSString * unit = @"b";
    double val = bytes;
    if (val>1024.) {
        val/=1024.;
        unit = @"Kb";
    }
    if (val>1024.) {
        val/=1024.;
        unit = @"Mb";
    }
    if (val>1024.) {
        val/=1024.;
        unit = @"Gb";
    }
    return [NSString stringWithFormat:@"%.1f %@", val, unit];
}

+(double)kilojoulesFromWatts:(double)watts andSeconds:(double)seconds{
    // http://www.rapidtables.com/convert/electric/watt-to-kj.htm
    return watts * seconds/1000.;
}

+(double)wattsFromKilojoules:(double)kj andSeconds:(double)seconds{
    return kj*1000./seconds;
}

+(double)stepsForCadence:(double)cadence andSeconds:(double)seconds{
    return cadence * seconds / 60.;
}
+(double)cadenceForSteps:(double)steps andSeconds:(double)seconds{
    return  steps * 60. / seconds;
}

GCUNITFORKEY(kilobyte);
GCUNITFORKEY(year);
GCUNITFORKEY(kilocalorie);
GCUNITFORKEY(centimeter);
GCUNITFORKEY(megabyte);
GCUNITFORKEY(ms);
GCUNITFORKEY(sec100m);
GCUNITFORKEY(mile);
GCUNITFORKEY(yard);
GCUNITFORKEY(joule);
GCUNITFORKEY(dateyear);
GCUNITFORKEY(kph);
GCUNITFORKEY(millimeter);
GCUNITFORKEY(date);
GCUNITFORKEY(timeofday);
GCUNITFORKEY(mps);
GCUNITFORKEY(meterperhour);
GCUNITFORKEY(stride);
GCUNITFORKEY(foot);
GCUNITFORKEY(shots);
GCUNITFORKEY(datetime);
GCUNITFORKEY(numberOfActivities);
GCUNITFORKEY(stepsPerMinute);
GCUNITFORKEY(hydph);
GCUNITFORKEY(te);
GCUNITFORKEY(sampleCount);
GCUNITFORKEY(minpermile);
GCUNITFORKEY(cpm);
GCUNITFORKEY(secperkm);
GCUNITFORKEY(strideyd);
GCUNITFORKEY(mph);
GCUNITFORKEY(dd);
GCUNITFORKEY(revolution);
GCUNITFORKEY(inch);
GCUNITFORKEY(strokesPerMinute);
GCUNITFORKEY(datemonth);
GCUNITFORKEY(doubleStepsPerMinute);
GCUNITFORKEY(kilogram);
GCUNITFORKEY(dimensionless);
GCUNITFORKEY(minute);
GCUNITFORKEY(secpermile);
GCUNITFORKEY(min100m);
GCUNITFORKEY(second);
GCUNITFORKEY(celsius);
GCUNITFORKEY(percent);
GCUNITFORKEY(minperkm);
GCUNITFORKEY(sec100yd);
GCUNITFORKEY(hour);
GCUNITFORKEY(feetperhour);
GCUNITFORKEY(gigabyte);
GCUNITFORKEY(yearly);
GCUNITFORKEY(semicircle);
GCUNITFORKEY(kilojoule);
GCUNITFORKEY(day);
GCUNITFORKEY(step);
GCUNITFORKEY(radian);
GCUNITFORKEY(centimetersPerMillisecond);
GCUNITFORKEY(meter);
GCUNITFORKEY(pound);
GCUNITFORKEY(bpm);
GCUNITFORKEY(dateshort);
GCUNITFORKEY(strideRate);
GCUNITFORKEY(mpm);
GCUNITFORKEY(development);
GCUNITFORKEY(min100yd);
GCUNITFORKEY(cps);
GCUNITFORKEY(watt);
GCUNITFORKEY(byte);
GCUNITFORKEY(hmph);
GCUNITFORKEY(volt);
GCUNITFORKEY(fahrenheit);
GCUNITFORKEY(gram);
GCUNITFORKEY(weekly);
GCUNITFORKEY(terabyte);
GCUNITFORKEY(monthly);
GCUNITFORKEY(rpm);
GCUNITFORKEY(kilometer);
GCUNITFORKEY(usgallon);
GCUNITFORKEY(liter);
GCUNITFORKEY(avgasKilogram)
GCUNITFORKEY(avgasPound)
GCUNITFORKEY(hobbshour)
GCUNITFORKEY(decimalhour)
GCUNITFORKEY(nm)

@end




