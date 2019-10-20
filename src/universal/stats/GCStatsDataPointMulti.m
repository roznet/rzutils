//  MIT Licence
//
//  Created on 05/01/2014.
//
//  Copyright (c) 2014 Brice Rosenzweig.
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

#import "GCStatsDataPointMulti.h"
#import "RZMacros.h"

#define GC_CODER_Z_DATA @"z_data"

@implementation GCStatsDataPointMulti

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.z_data = [aDecoder decodeDoubleForKey:GC_CODER_Z_DATA];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];

    [aCoder encodeDouble:self.z_data forKey:GC_CODER_Z_DATA];
}


+(GCStatsDataPointMulti*)dataPointWithDate:(NSDate*)aDate y:(double)y andZ:(double)z{
    GCStatsDataPointMulti * rv = RZReturnAutorelease([[GCStatsDataPointMulti alloc] init]);
    if (rv) {
        rv.x_data = aDate.timeIntervalSinceReferenceDate;
        rv.y_data = y;
        rv.z_data = z;
    }
    return rv;
}

+(GCStatsDataPointMulti*)dataPointWithX:(double)x y:(double)y andZ:(double)z{
    GCStatsDataPointMulti * rv = RZReturnAutorelease([[GCStatsDataPointMulti alloc] init]);
    if (rv) {
        rv.x_data = x;
        rv.y_data = y;
        rv.z_data = z;
    }
    return rv;

}
-(GCStatsDataPointMulti*)copy{
    GCStatsDataPointMulti * rv = RZReturnAutorelease([[self.class alloc] init]);
    if (rv) {
        rv.x_data = self.x_data;
        rv.y_data = self.y_data;
        rv.z_data = self.z_data;
        
    }
    return rv;
}

@end
