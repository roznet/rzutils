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

#import "GCUnitInverseLinear.h"

#pragma mark -
@implementation GCUnitInverseLinear
@synthesize multiplier,offset;

+(GCUnitInverseLinear*)unitInverseLinearWithArray:(NSArray*)defs reference:(NSString*)ref multiplier:(double)aMult andOffset:(double)aOffset{
    GCUnitInverseLinear * rv = RZReturnAutorelease([[GCUnitInverseLinear alloc] initWithArray:defs]) ;
    if (rv) {
        rv.multiplier = aMult;
        rv.offset = aOffset;
        rv.referenceUnitKey = ref;
    }
    return rv;
}
-(BOOL)betterIsMin{
    return true;
}

-(double)valueToReferenceUnit:(double)aValue{
    return 1./aValue * multiplier + offset;
}
-(double)valueFromReferenceUnit:(double)aValue{
    return 1./ aValue * multiplier - offset;
}

@end
