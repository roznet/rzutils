//  MIT Licence
//
//  Created on 19/12/2013.
//
//  Copyright (c) 2013 Brice Rosenzweig.
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

#import "GCUnitPerformanceRange.h"

#pragma mark -
@implementation GCUnitPerformanceRange

+(GCUnitPerformanceRange*)performanceUnitFrom:(double)aMin to:(double)aMax{
    GCUnitPerformanceRange * rv = RZReturnAutorelease([[self alloc] init]);
    if (rv) {
        rv.min = aMin;
        rv.max = aMax;
    }
    return rv;
}
-(NSString*)formatDouble:(double)aDbl addAbbr:(BOOL)addAbbr{
    double val = (aDbl-self.min)/(self.max-self.min)*100.;
    return [NSString stringWithFormat:@"%.1f", val];
}


@end
