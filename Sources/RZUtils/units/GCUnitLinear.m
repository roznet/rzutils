//  MIT Licence
//
//  Created on 16/04/2021.
//
//  Copyright (c) 2021 Brice Rosenzweig.
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


#import "GCUnitLinear.h"

#pragma mark -
@implementation GCUnitLinear
@synthesize multiplier,offset;

+(GCUnitLinear*)unitLinearWithArray:(NSArray*)defs reference:(NSString*)ref multiplier:(double)aMult andOffset:(double)aOffset{
    GCUnitLinear * rv = RZReturnAutorelease([[GCUnitLinear alloc] initWithArray:defs]);
    if (rv) {
        rv.multiplier = aMult;
        rv.offset = aOffset;
        rv.referenceUnitKey = ref;
    }
    return rv;
}

-(double)valueToReferenceUnit:(double)aValue{
    // Multiplier is how many reference unit in unit
    // km mult=1000 m (ref unit=m)
    // x km -> x * 1000 m
    // x m  -> x / 1000 km
    // miles mult = 1609m (ref unit=m)
    // x miles -> x*1609 m
    // x m -> x/1609m
    // x km -> x*1000 m / 1609m
    return aValue * multiplier + offset;
}
-(double)valueFromReferenceUnit:(double)aValue{
    return (aValue-offset) / multiplier;
}

@end

