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

#import "GCUnitElapsedSince.h"

@interface GCUnitElapsedSince ()
@property (nonatomic,retain) NSDate * since;
@property (nonatomic,retain) GCUnit * second;
@end

@implementation GCUnitElapsedSince

#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_since release];
    [_second release];
    [super dealloc];
}
#endif

+(GCUnitElapsedSince*)elapsedSince:(NSDate *)date{
    GCUnitElapsedSince * rv = RZReturnAutorelease([[GCUnitElapsedSince alloc] init]);
    if( rv ){
        rv.key = [NSString stringWithFormat:@"elapsedSince(%@)", date];
        rv.second = [GCUnit second];
        rv.since = date;
    }
    return rv;
}
/*
-(double)axisKnobSizeFor:(double)range numberOfKnobs:(NSUInteger)n{
    return [self.second axisKnobSizeFor:range numberOfKnobs:n];
}

-(NSArray*)axisKnobs:(NSUInteger)nKnobs min:(double)x_min max:(double)x_max extendToKnobs:(BOOL)extend{


    return [self.second axisKnobs:nKnobs min:(x_min - self.since.timeIntervalSinceReferenceDate) max:(x_max-self.since.timeIntervalSinceReferenceDate) extendToKnobs:extend];
}
*/
-(NSString*)formatDouble:(double)aDbl addAbbr:(BOOL)addAbbr{
    return [self.second formatDouble:(aDbl-self.since.timeIntervalSinceReferenceDate) addAbbr:addAbbr];
}


@end


