//  MIT Licence
//
//  Created on 22/09/2012.
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

#import "GCSimpleGraphView.h"
#import "RZViewConfig.h"
#import "RZLog.h"
#import "RZMacros.h"

#if TARGET_OS_IPHONE
#define UIGRAPHICCURRENTCONTEXT() UIGraphicsGetCurrentContext()
#else
#import <CoreGraphics/CoreGraphics.h>
#import "NSBezierPath+QuartzHelper.h"
#import <AppKit/AppKit.h>
#define UIGRAPHICCURRENTCONTEXT() [[NSGraphicsContext currentContext] CGContext]
#endif


@interface GCSimpleGraphViewContext : NSObject
@property (nonatomic,retain) GCViewGradientColors * gradientColors;
@property (nonatomic,retain) GCViewGradientColors * gradientColorsFill;
@property (nonatomic,retain) GCStatsDataSerie * gradientDataSerie;
@property( nonatomic,retain) NSObject<GCStatsFunction>*gradientFunction;

@property (nonatomic,retain) RZColor * strokeColor;
@property (nonatomic,retain) RZColor * fillColor;

@property (nonatomic,assign) CGPoint from;
@property (nonatomic,assign) CGPoint to;

@property (nonatomic,assign) CGPoint from_adj;
@property (nonatomic,assign) CGPoint to_adj;

@property (nonatomic,assign) CGPoint range_min;
@property (nonatomic,assign) CGPoint range_max;

@property (nonatomic,assign) BOOL barGraph;

-(GCSimpleGraphViewContext*)initWithSource:(NSObject<GCSimpleGraphDataSource>*)dataSource config:(NSObject<GCSimpleGraphDisplayConfig>*)displayConfig forIndex:(NSUInteger)idx;
@end

@implementation GCSimpleGraphViewContext

-(GCSimpleGraphViewContext*)initWithSource:(NSObject<GCSimpleGraphDataSource>*)dataSource config:(NSObject<GCSimpleGraphDisplayConfig>*)displayConfig forIndex:(NSUInteger)idx{
    self = [super init];
    if( self ){
        self.barGraph = ([displayConfig graphTypeForSerie:idx] == gcGraphStep);
        self.gradientColors = [displayConfig respondsToSelector:@selector(gradientColors:)] ? [displayConfig gradientColors:idx] : nil;
        self.gradientColorsFill = [displayConfig respondsToSelector:@selector(gradientColorsFill:)] ? [displayConfig gradientColorsFill:idx] : nil;
        self.gradientFunction = [dataSource respondsToSelector:@selector(gradientFunction:)] ? [dataSource gradientFunction:idx] : nil;
        self.gradientDataSerie = [dataSource respondsToSelector:@selector(gradientDataSerie:)] ? [dataSource gradientDataSerie:idx] : nil;
        
        // Init color with default
        self.strokeColor = [displayConfig colorForSerie:idx];
        self.fillColor = [displayConfig fillColorForSerie:idx];

        if( [displayConfig graphTypeForSerie:idx]== gcGraphStep ){
            if( self.gradientColors && self.gradientColorsFill == nil ){
                self.gradientColorsFill = self.gradientColors;
            }
            if( self.fillColor == nil ){
                self.fillColor = self.strokeColor;
            }
        }
    }
    return self;
}
#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_gradientColors release];
    
    [super dealloc];
}
#endif

-(void)updateColorsForIndex:(NSUInteger)idx{
    if( self.gradientColors || self.gradientColorsFill){
        GCStatsDataPoint * gradientPoint = [self.gradientDataSerie dataPointAtIndex:idx];
        CGFloat val = self.gradientFunction ? [self.gradientFunction valueForX:gradientPoint.x_data] : gradientPoint.y_data;
        if( self.gradientColors ){
            self.strokeColor = [self.gradientColors colorsForValue:val];
        }
        if( self.gradientColorsFill ){
            self.fillColor = [self.gradientColorsFill colorsForValue:val];
        }
    }
}

-(void)updateWithFirstCGPoint:(CGPoint)first{
    self.from = first;
    self.to = first;
}

-(BOOL)updateWithCGPoint:(CGPoint)point lastPointHadValue:(BOOL)lastPointHasValue{
    self.from = self.to;
    self.to = point;
    
    self.from_adj = _from;
    self.to_adj = _to;
    if( !lastPointHasValue ){
        _from_adj = _to;
    }
    
    if (_from_adj.y>_range_max.y || _from_adj.y<_range_min.y) {
        _from_adj.y = MAX(MIN(_from_adj.y, _range_max.y),_range_min.y);
        _from_adj.x = _from.x+(_from_adj.y-_from.y)/(_to.y-_from.y)*(_to.x-_from.x);
    }
    if (_from_adj.x>_range_max.x || _from_adj.x<_range_min.x) {
        _from_adj.x = MAX(MIN(_from_adj.x,_range_max.x),_range_min.x);
        _from_adj.y = _from.y+(_from_adj.x-_from.x)/(_to.x-_from.x)*(_to.y-_from.y);
    }
    if (_to_adj.y>_range_max.y || _to_adj.y<_range_min.y) {
        _to_adj.y = MAX(MIN(_to_adj.y, _range_max.y), _range_min.y);
        _to_adj.x = _from.x+(_to_adj.y-_from.y)/(_to.y-_from.y)*(_to.x-_from.x);
    }
    if (_to_adj.x>_range_max.x || _to_adj.x<_range_min.x) {
        _to_adj.x = MAX(MIN(_to_adj.x, _range_max.x), _range_min.x);
        _to_adj.y = _from.y+(_to_adj.x-_from.x)/(_to.x-_from.x)*(_to.y-_from.y);
    }

    if( _barGraph ){
        _to_adj.y = _from_adj.y;
    }
    return point.x >= _range_min.x || point.x <= _range_max.x;
}

@end

@interface GCSimpleGraphView ()
@end

@implementation GCSimpleGraphView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.displayConfig = RZReturnAutorelease([[GCSimpleGraphDefaultDisplayConfig alloc] init]);
        self.geometries = [NSMutableArray arrayWithCapacity:2];
    }
    return self;
}

#if ! __has_feature(objc_arc)
-(void)dealloc{
    [_geometries release];
    [_dataSource release];
    [_displayConfig release];
    /*
    if (_backgroundGradient) {
        CGGradientRelease(_backgroundGradient);
    }*/
    [super dealloc];
}
#endif

#pragma mark - Geometry

-(BOOL)xAxisIsVertical{
    return [_displayConfig respondsToSelector:@selector(xAxisIsVertical)] ? [_displayConfig xAxisIsVertical] : false;
}

-(GCSimpleGraphGeometry *)geometryForIndex:(NSUInteger)idx{
    NSUInteger axis = [_dataSource respondsToSelector:@selector(axisForSerie:)]?[_dataSource axisForSerie:idx]:0;

    if (axis < (self.geometries).count) {
        return (self.geometries)[axis];
    }

    return (self.geometries).count>0? (self.geometries)[0] : nil;
}

-(void)calculateGeometry{
    self.geometries = [NSMutableArray arrayWithCapacity:2];

    CGPoint zoom= CGPointMake(0., 0.);
    CGPoint offset = CGPointMake(0., 0.);
    if ([_displayConfig respondsToSelector:@selector(zoomPercentage)] && [_displayConfig respondsToSelector:@selector(offsetPercentage)]) {
        zoom = [_displayConfig zoomPercentage];
        offset = [_displayConfig offsetPercentage];
    }

    BOOL xAxisIsVertical = [_displayConfig respondsToSelector:@selector(xAxisIsVertical)] ? [_displayConfig xAxisIsVertical] : false;
    BOOL maximizeGraph = [_displayConfig respondsToSelector:@selector(maximizeGraph)]?[_displayConfig maximizeGraph]:false;

    CGRect baseRect = self.drawRect;

    if (baseRect.size.width == 0 && self.frame.size.width != 0) {
        self.drawRect = self.frame;
    }
    for (NSUInteger i=0; i<[_dataSource nDataSeries]; i++) {
        NSUInteger axis = [_dataSource respondsToSelector:@selector(axisForSerie:)]?[_dataSource axisForSerie:i]:0;
        if (axis>=(self.geometries).count) {

            GCSimpleGraphGeometry * geometry = RZReturnAutorelease([[GCSimpleGraphGeometry alloc] init]);
            geometry.drawRect = self.drawRect;
            geometry.zoomPercentage = zoom;
            geometry.offsetPercentage = offset;
            geometry.dataSource = _dataSource;
            geometry.axisIndex = axis;
            geometry.serieIndex = i;
            geometry.xAxisIsVertical = xAxisIsVertical;
            geometry.maximizeGraph = maximizeGraph;
            [geometry calculate];
            [self.geometries addObject:geometry];
        }
    }
}


#pragma mark - Colors

-(RZColor*)axisColor{
    RZColor * rv = nil;

    if ([self.displayConfig respondsToSelector:@selector(axisColor)]) {
        rv = [self.displayConfig axisColor];
    }
    if (rv == nil) {
        rv = [RZColor blueColor];
    }

    return rv;
}

-(RZColor*)useBackgroundColor{
    if ([self.displayConfig respondsToSelector:@selector(useBackgroundColor)]) {
        RZColor * color = [self.displayConfig useBackgroundColor];
        if (color) {
            return color;
        }
    }
    return [RZColor whiteColor];
}

-(RZColor*)useForegroundColor{
    if ([self.displayConfig respondsToSelector:@selector(useForegroundColor)]) {
        RZColor * color = [self.displayConfig useForegroundColor];
        if (color) {
            return color;
        }
    }
    return [RZColor blackColor];
}

-(RZColor*)graphColor:(NSUInteger)idx{
    RZColor * color = [_displayConfig colorForSerie:idx];
    if ([color isEqual:[self useBackgroundColor]]) {
        color = [self useForegroundColor];
    }
    return color;
}

-(RZColor*)graphFillColor:(NSUInteger)idx{
    RZColor * fillColor = nil;
    if ([_displayConfig respondsToSelector:@selector(fillColorForSerie:)]) {
        fillColor = [_displayConfig fillColorForSerie:idx];
    }
    if( fillColor == nil && [self.displayConfig graphTypeForSerie:idx] == gcGraphStep){
        fillColor = [self graphColor:idx];
    }

    return fillColor;
}

#pragma mark - Graph Drawing

-(void)drawGraphLines:(NSUInteger)idx{

    BOOL barGraph = ([_displayConfig graphTypeForSerie:idx] == gcGraphStep);
    
    NSUInteger i = 0;
    GCStatsDataSerie * data = [_dataSource dataSerie:idx];
    GCSimpleGraphGeometry * geometry = [self geometryForIndex:idx];

    NSUInteger n = [data count];
    if (data == nil || n == 0) {
        return;
    }
    CGFloat lineWidth = [_displayConfig lineWidth:idx];

    GCSimpleGraphViewContext * simpleContext = RZReturnAutorelease([[GCSimpleGraphViewContext alloc] initWithSource:self.dataSource config:self.displayConfig forIndex:idx]);

    simpleContext.range_min = geometry.rangeMinPoint;
    simpleContext.range_max = geometry.rangeMaxPoint;

    CGRect dataXYRect = geometry.dataXYRect;
    CGPoint axis = [geometry pointForX:dataXYRect.origin.x andY:dataXYRect.origin.y];

    GCStatsDataPoint * point = [data dataPointAtIndex:0];
    
    [simpleContext updateWithFirstCGPoint:[geometry pointForX:point.x_data andY:point.y_data]];
    
    // Keep track of last point we drew so if too many too close we skip them
    CGFloat last_drawn_point_x = simpleContext.to_adj.x;
    int badpoints=0;
    
    RZBezierPath * path = [RZBezierPath bezierPath];
    path.lineWidth = lineWidth;
    
    if (CGRectContainsPoint(self.drawRect, simpleContext.to)) {
        [path moveToPoint:simpleContext.to];
    }

    // First point in a path that need to be filled
    CGPoint first = simpleContext.to;

    [simpleContext updateColorsForIndex:0];
    
    RZColor * strokeColor = simpleContext.strokeColor;
    RZColor * nextStrokeColor = strokeColor;

    RZColor * fillColor = simpleContext.fillColor;
    RZColor * nextFillColor = fillColor;

    [strokeColor?:[RZColor clearColor] setStroke];
    [fillColor?:[RZColor clearColor] setFill];

    BOOL shouldFill = (fillColor != nil);
    BOOL shouldFillNext = shouldFill;

    NSUInteger paths = 0;
    NSDate * start = [NSDate date];
    BOOL lastPointHasValue = true;
    
    
    for (i=1; i<n; i++) {

        BOOL endCurrentPathSegment = false;
        BOOL addCurrentPoint = true;
        BOOL isLastPoint = (i==n-1);

        point = [data dataPointAtIndex:i];

        if (!point.hasValue) {
            endCurrentPathSegment = true;
            addCurrentPoint = false;
            lastPointHasValue = false;
            shouldFillNext = false;
        }else{
            shouldFillNext = (fillColor != nil);
        }

        if( [simpleContext updateWithCGPoint:[geometry pointForX:point.x_data andY:point.y_data]
                           lastPointHadValue:lastPointHasValue] ){
            [simpleContext updateColorsForIndex:i];
            
            if (simpleContext.strokeColor && ![simpleContext.strokeColor isEqual:strokeColor]) {
                endCurrentPathSegment = true;
                nextStrokeColor = simpleContext.strokeColor;
            }
            if( simpleContext.fillColor && ![simpleContext.fillColor isEqual:fillColor] ){
                endCurrentPathSegment = true;
                nextFillColor = simpleContext.fillColor;
            }

        }else{
            addCurrentPoint = false;
        }

        if ( addCurrentPoint ) {
            if (path.empty) {
                // If starting a new path segment, first move to the start and
                // record first point of the segment
                [path moveToPoint:simpleContext.from_adj];
                first = simpleContext.from_adj;
            }
            // Only draw next point if x has moved than more than 0.5
            if (fabs(simpleContext.to_adj.x-last_drawn_point_x)>0.5) {
                paths++;
                [path addLineToPoint:simpleContext.to_adj];
                last_drawn_point_x = simpleContext.to_adj.x;
            }
            lastPointHasValue = true;
        }

        // Stroke and check for fill before start of new segment or end of the graph
        // bar graph also should always fill
        if( endCurrentPathSegment || isLastPoint || barGraph){
            if (!path.empty) {
                [path stroke];
                if (shouldFill) {
                    [fillColor setFill];

                    RZBezierPath * pathIn = [RZBezierPath bezierPathWithCGPath:path.CGPath];
                    [pathIn addLineToPoint:CGPointMake(simpleContext.to_adj.x, axis.y)];
                    [pathIn addLineToPoint:CGPointMake(first.x, axis.y)];
                    [pathIn addLineToPoint:CGPointMake(first.x, first.y)];
                    [pathIn fill];
                    if( barGraph ){
                        // Bar graph should highlight the bars
                        [pathIn stroke];
                    }
                }
            }
            fillColor = nextFillColor;
            strokeColor = nextStrokeColor;
            [strokeColor setStroke];
            [path removeAllPoints];
            paths = 0;
        }
        shouldFill = shouldFillNext;
    }

    BOOL highlightCurrent = [_displayConfig highlightCurrent:idx];
    CGPoint currentPoint = [_dataSource currentPoint:idx];
    BOOL disableHighlight = [_displayConfig disableHighlight:idx];

    if (!disableHighlight && highlightCurrent) {
        CGPoint hPoint = [geometry pointForX:currentPoint.x andY:currentPoint.y];
        CGPoint yPoint = CGPointMake(simpleContext.range_min.x, hPoint.y);
        CGPoint xPoint = CGPointMake(hPoint.x, simpleContext.range_min.y);
        [[RZColor blackColor] setStroke];
        RZBezierPath * pathIn = [RZBezierPath bezierPath];

        [pathIn moveToPoint:yPoint];
        [pathIn addLineToPoint:hPoint];
        [pathIn addLineToPoint:xPoint];

        [pathIn stroke];
    }

    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
    if (elapsed>0.1) {
        RZLog(RZLogWarning, @"paths %d pts/%d in %0.1f secs %@", (int)paths, (int)[data count], elapsed, [_dataSource title]);
    }
    if (badpoints>1) {
        RZLog(RZLogWarning, @"Total of %d bad points", badpoints);
    }

}

-(void)drawGraphBars:(NSUInteger)idx{
    NSUInteger i = 0;
    GCStatsDataSerie * data = [_dataSource dataSerie:idx];
    GCSimpleGraphGeometry * geometry = [self geometryForIndex:idx];

    NSUInteger n = [data count];
    if (data == nil || n == 0) {
        return;
    }

    BOOL xAxisIsVertical = [_displayConfig respondsToSelector:@selector(xAxisIsVertical)] ? [_displayConfig xAxisIsVertical] : false;

    RZColor * color = [self graphColor:idx];

    GCViewGradientColors * gradientColors = nil;
    GCViewGradientColors * gradientColorsFill = nil;
    id<GCStatsFunction> gradientFunction = nil;
    GCStatsDataSerie * gradientDataSerie = nil;

    gcStatsRange range= geometry.range;
    CGPoint range_min = geometry.rangeMinPoint;
    CGPoint range_max = geometry.rangeMaxPoint;

    if (xAxisIsVertical) {
        range_min = geometry.rangeMaxPoint;
        range_max = geometry.rangeMinPoint;
    }

    CGRect dataXYRect = geometry.dataXYRect;
    CGPoint axis=[geometry pointForX:dataXYRect.origin.x andY:dataXYRect.origin.y];
    GCStatsDataPoint * point = [data dataPointAtIndex:0];
    CGPoint last      = [geometry pointForX:point.x_data andY:point.y_data];

    CGContextRef context = UIGRAPHICCURRENTCONTEXT();
    [color setFill];
    [color setStroke];
    CGPoint rightMost = last;
    BOOL skip = false;
    for (i=1; i<n; i++) {
        CGPoint from    = last;

        point = [data dataPointAtIndex:i];
        CGPoint to      = [geometry pointForX:point.x_data andY:point.y_data];
        skip = [[data dataPointAtIndex:i-1] isKindOfClass:[GCStatsDataPointNoValue class]];
        if (to.x >= range_min.x || to.x <= range_max.x) {
            if (gradientColors && gradientDataSerie) {
                CGFloat val = gradientFunction ?
                [gradientFunction valueForX:point.x_data]
                :
                [gradientDataSerie dataPointAtIndex:i-1].y_data;
                RZColor * thisColor = [gradientColors colorsForValue:val];
                [thisColor setStroke];
                [thisColor setFill];
            }

            CGPoint from_adj = from;
            CGPoint to_adj   = to;

            if (xAxisIsVertical) {
                to_adj.x = from_adj.x;
            }else{
                to_adj.y = from_adj.y;
            }
            if (!skip) {
                CGRect marker;
                if (xAxisIsVertical) {
                    marker = CGRectMake(from_adj.x, from_adj.y, -(from_adj.x-axis.x), to_adj.y-from_adj.y);
                }else{
                    marker = CGRectMake(from_adj.x, from_adj.y, to_adj.x-from_adj.x, -(from_adj.y-axis.y));
                }
                //NSLog(@"%lu: %@ %@", (unsigned long)i, NSStringFromCGPoint(to),  NSStringFromCGRect(marker));
                CGContextFillRect(context, marker);
                CGContextStrokeRect(context, marker);
            }
            if (to.x > rightMost.x) {
                rightMost = to;
            }
        }
        last = to;
    }
    if (!xAxisIsVertical && rightMost.x < range_max.x) {
        CGRect marker = CGRectMake(rightMost.x, rightMost.y, range.x_max-rightMost.x, -(rightMost.y-axis.y));
        CGContextFillRect(context, marker);
        CGContextStrokeRect(context, marker);
    }

}
-(void)drawGraphXY:(NSUInteger)idx{
    NSUInteger i = 0;
    GCStatsDataSerie * data = [_dataSource dataSerie:idx];

    GCSimpleGraphGeometry * geometry = [self geometryForIndex:idx];

    NSUInteger n = [data count];
    if (data == nil || n == 0) {
        return;
    }

    CGFloat lineWidth = [_displayConfig lineWidth:idx];

    GCSimpleGraphViewContext * simpleContext = [[GCSimpleGraphViewContext alloc] initWithSource:self.dataSource config:self.displayConfig forIndex:idx];

    CGPoint range_min = geometry.rangeMinPoint;
    CGPoint range_max = geometry.rangeMaxPoint;

    CGFloat x = [data dataPointAtIndex:0].x_data;
    CGFloat y = [data dataPointAtIndex:0].y_data;
    CGPoint first =[geometry pointForX:x andY:y];
    
    RZBezierPath * path = nil;

    [simpleContext updateColorsForIndex:0];
    
    path = [RZBezierPath bezierPath];
    path.lineWidth = lineWidth;
    if (CGRectContainsPoint(self.drawRect, first)) {
        [path moveToPoint:first];
    }
    
    CGContextRef context = UIGRAPHICCURRENTCONTEXT();

    CGPoint to = CGPointMake(0., 0.);
    BOOL hasTransparent = false;
    for (NSUInteger ii=0; ii<n; ii++) {
        //i = n-1-ii;
        i = ii;
        [simpleContext updateColorsForIndex:i];
        
        if (CGColorGetAlpha(simpleContext.strokeColor.CGColor)<1.) {
            hasTransparent = true;
        }

        [[RZColor blackColor] setStroke];
        [simpleContext.strokeColor setFill];
        
        to = [geometry pointForX:[data dataPointAtIndex:i].x_data andY:[data dataPointAtIndex:i].y_data];
        if (to.x >= range_min.x && to.x <= range_max.x && to.y >= range_min.y && to.y <= range_max.y) {
            CGRect marker = CGRectMake(to.x-lineWidth/2., to.y-lineWidth/2., lineWidth, lineWidth);
            CGContextFillRect(context, marker);
        }
    }

    if (hasTransparent) {
        // second layer to highlight non transparent
        for (NSUInteger ii=0; ii<n; ii++) {
            //i = n-1-ii;
            i = ii;
            [simpleContext updateColorsForIndex:i];

            if (CGColorGetAlpha(simpleContext.strokeColor.CGColor)<1.) {
                continue;
            }
            [[RZColor blackColor] setStroke];
            [simpleContext.strokeColor setFill];
            
            to = [geometry pointForX:[data dataPointAtIndex:i].x_data andY:[data dataPointAtIndex:i].y_data];
            if (to.x > range_min.x && to.x < range_max.x && to.y > range_min.y && to.y < range_max.y) {
                CGRect marker = CGRectMake(to.x-lineWidth/2., to.y-lineWidth/2., lineWidth, lineWidth);
                CGContextFillRect(context, marker);
            }
        }
    }
    BOOL highlightCurrent = [_displayConfig highlightCurrent:idx];
    CGPoint currentPoint = [_dataSource currentPoint:idx];
    BOOL disableHighlight = [_displayConfig disableHighlight:idx];

    if (!disableHighlight) {
        if (highlightCurrent) {
            to = [geometry pointForX:currentPoint.x andY:currentPoint.y];
        }
        CGContextSetStrokeColorWithColor(context, [self useBackgroundColor].CGColor);
        CGContextSetFillColorWithColor(context, [self useBackgroundColor].CGColor);
        CGRect marker = CGRectMake(to.x-lineWidth/2., to.y-lineWidth/2., lineWidth, lineWidth);
        CGContextStrokeRect(context, marker);
        CGContextFillRect(context, marker);
        lineWidth+=1.;
        CGContextSetStrokeColorWithColor(context, [self useForegroundColor].CGColor);
        marker = CGRectMake(to.x-lineWidth/2., to.y-lineWidth/2., lineWidth, lineWidth);
        CGContextStrokeRect(context, marker);
    }

}
#pragma mark - Drawing Areas

-(void)drawAxisKnobs{
    GCSimpleGraphGeometry * geometry = [self geometryForIndex:0];

    CGRect baseRect = self.drawRect;

    NSString * title = [_dataSource title];
    NSDictionary * titleAttr = @{NSFontAttributeName:[geometry titleFont]?:[RZViewConfig systemFontOfSize:12.],NSForegroundColorAttributeName:self.useForegroundColor};
    NSDictionary * knobAttr = @{NSFontAttributeName:[geometry axisFont]?:[RZViewConfig systemFontOfSize:12.],NSForegroundColorAttributeName:self.useForegroundColor};
    gcGraphType gtype = [_displayConfig graphTypeForSerie:0];

    [geometry calculateAxisKnobRect:gtype andAttribute:knobAttr];

    [title drawInRect:geometry.titleRect withAttributes:titleAttr];

    [[self axisColor] setStroke];

    GCAxisKnob * last = nil;

    BOOL xAxisIsVertical = self.xAxisIsVertical;

    for (GCAxisKnob * aKnob in geometry.xAxisKnobs) {
        if (aKnob.rect.size.width > 0. ) {
            if (last && [last.label isEqualToString:aKnob.label]) {
                // Skip if same text as last one to avoid duplicate
            }else{
                BOOL tooClose = false;
                if (last) {
                    if (xAxisIsVertical) {
                        tooClose = (last.rect.origin.y - CGRectGetMaxY( aKnob.rect)) < last.rect.size.height/3.;
                    }else{
                        tooClose = (aKnob.rect.origin.x - CGRectGetMaxX(last.rect)) < last.rect.size.width/3.;
                    }
                }
                if (!tooClose) {
                    [aKnob.label drawInRect:aKnob.rect withAttributes:knobAttr];
                    last = aKnob;
                }
            }

            CGPoint one = [geometry pointForX:aKnob.value andY:geometry.knobRange.y_min];
            if (CGRectContainsPoint(baseRect, one)) {
                RZBezierPath * path = [[RZBezierPath alloc] init];
                [path moveToPoint:one];
                if (xAxisIsVertical) {
                    one.x -= 2.;
                }else{
                    one.y+=2.;
                }
                [path addLineToPoint:one];
                [path stroke];
                RZRelease(path);
            }

        }
    }

    [[RZColor lightGrayColor] setStroke];
    [[RZColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.2] setStroke];
    //CGFloat dashPattern[2] = {1.0, 1.0};

    CGFloat x_min = geometry.dataXYRect.origin.x;
    CGFloat x_max = geometry.dataXYRect.origin.x+geometry.dataXYRect.size.width;

    for (GCAxisKnob * aKnob in geometry.yAxisKnobs) {
        CGPoint start = [geometry pointForX:x_min andY:aKnob.value];
        CGPoint end   = [geometry pointForX:x_max andY:aKnob.value];

        if (CGRectContainsPoint(baseRect, aKnob.rect.origin) && CGRectContainsPoint(baseRect, end)) {
            RZBezierPath * path = [[RZBezierPath alloc] init];
            //[path setLineDash:dashPattern count:2 phase:0.0];

            path.lineWidth = 0.5;
            CGFloat dashes[] = {1., 2.};
            [path setLineDash:dashes count:2 phase:4];
            [path moveToPoint:start];
            [path addLineToPoint:end];
            [path stroke];
            RZRelease(path);

            [aKnob.label drawInRect:aKnob.rect withAttributes:knobAttr];
        }
    }
}

-(void)drawAxis{
    GCSimpleGraphGeometry * geometry = [self geometryForIndex:0];

    RZBezierPath * axis = [RZBezierPath bezierPath];
    if (self.xAxisIsVertical) {
        CGRect dataXYRect = geometry.dataXYRect;
        CGPoint topLeft = [geometry pointForX:dataXYRect.origin.x+dataXYRect.size.width andY:dataXYRect.origin.y];
        CGPoint bottomLeft = [geometry pointForX:dataXYRect.origin.x andY:dataXYRect.origin.y];
        CGPoint bottomRight = [geometry pointForX:dataXYRect.origin.x andY:dataXYRect.origin.y+dataXYRect.size.height];
        if (CGRectContainsPoint(self.drawRect, topLeft)
            && CGRectContainsPoint(self.drawRect, bottomLeft)
            && CGRectContainsPoint(self.drawRect, bottomRight)) {
            [axis moveToPoint:topLeft];
            [axis addLineToPoint:bottomLeft];
            [axis addLineToPoint:bottomRight];
            [[self axisColor] setStroke];
            [axis stroke];
        }
    }else{
        CGRect dataXYRect = geometry.dataXYRect;
        CGPoint topLeft = [geometry pointForX:dataXYRect.origin.x andY:dataXYRect.origin.y+dataXYRect.size.height];
        CGPoint bottomLeft = [geometry pointForX:dataXYRect.origin.x andY:dataXYRect.origin.y];
        CGPoint bottomRight = [geometry pointForX:dataXYRect.origin.x+dataXYRect.size.width andY:dataXYRect.origin.y];
        if (CGRectContainsPoint(self.drawRect, topLeft)
            && CGRectContainsPoint(self.drawRect, bottomLeft)
            && CGRectContainsPoint(self.drawRect, bottomRight)) {
            [axis moveToPoint:topLeft];
            [axis addLineToPoint:bottomLeft];
            [axis addLineToPoint:bottomRight];
            [[self axisColor] setStroke];
            [axis stroke];
        }
    }
}

-(void)drawPath:(NSUInteger)idx{
    gcGraphType type = [_displayConfig graphTypeForSerie:idx];

    switch (type) {
        case gcScatterPlot:
            [self drawGraphXY:idx];
            break;
        case gcGraphLine:
            [self drawGraphLines:idx];
            break;
        case gcGraphStep:
            [self drawGraphLines:idx];
            //[self drawGraphBars:idx];
            break;
    }

}

- (void)drawBackgroundGradient:(CGRect)rect {

    RZBezierPath * path = [ RZBezierPath bezierPathWithRect:rect];
    [[self useBackgroundColor] setFill];
    [[self useBackgroundColor] setStroke];
    [path fill];
}


-(void)drawRectEmptyGraph:(CGRect)rect{
    self.drawRect = self.frame;

#if TARGET_OS_IPHONE
    self.backgroundColor = [self useBackgroundColor];
#endif

    CGRect baseRect = self.drawRect;
    [self drawBackgroundGradient:rect];

    NSString * title = [_dataSource title];
    if (title) {
        NSDictionary * titleAttr = @{NSFontAttributeName:[RZViewConfig systemFontOfSize:12.],NSForegroundColorAttributeName:self.useForegroundColor};
        CGSize titleSize = [title sizeWithAttributes:titleAttr];

        CGRect titleRect = CGRectMake(baseRect.size.width/2.-titleSize.width/2., 5.,titleSize.width, titleSize.height);
        [title drawInRect:titleRect withAttributes:titleAttr];
    }

    NSString * emptyMsg = nil;
    if ([self.displayConfig respondsToSelector:@selector(emptyGraphLabel)]) {
        emptyMsg = [self.displayConfig emptyGraphLabel];
    }
    if (emptyMsg == nil) {
        emptyMsg = NSLocalizedString(@"Empty Graph", @"GraphView");
    }
    NSDictionary * msgAttr = @{NSFontAttributeName:[RZViewConfig systemFontOfSize:14.],NSForegroundColorAttributeName:self.useForegroundColor};
    CGSize msgSize = [emptyMsg sizeWithAttributes:msgAttr];

    CGRect msgRect = CGRectMake(baseRect.size.width/2.-msgSize.width/2., baseRect.size.height/2-msgSize.height/2,msgSize.width, msgSize.height);
    [emptyMsg drawInRect:msgRect withAttributes:msgAttr];

}

- (void)drawRect:(CGRect)rect {
    if ([_dataSource nDataSeries] == 0 ) {
        [self drawRectEmptyGraph:rect];
        return;
    }
    if ([[_dataSource dataSerie:0] count] == 0) {
        [self drawRectEmptyGraph:rect];
        return;
    }
    self.drawRect = rect;

    [self calculateGeometry];
    [self drawBackgroundGradient:rect];
    [self drawAxisKnobs];

    for (NSUInteger i = 0; i<[_dataSource nDataSeries]; i++) {
        [self drawPath:i];
    }
    [self drawAxis];
}

@end

@implementation GCSimpleGraphDefaultDisplayConfig

-(RZColor*)colorForSerie:(NSUInteger)idx{
    return [RZColor blackColor];
}

-(CGFloat)lineWidth:(NSUInteger)idx{
    return 1.;
}

-(gcGraphType)graphTypeForSerie:(NSUInteger)idx{
    return gcGraphLine;
}
-(BOOL)highlightCurrent:(NSUInteger)idx{
    return false;
}
-(BOOL)disableHighlight:(NSUInteger)idx{
    return false;
}

@end
