//
//  CCBarGraphView.m
//  CoreChart2D
//
//  Created by GoKu on 9/6/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBarGraphView.h"

static CGFloat const kOffsetX = 60;
static CGFloat const kOffsetY = 30;
static CGFloat const kOffsetYWithInfo = 40;

static CGFloat const kSeriesWidth = 120;
static CGFloat const kSeriesHeight = 20;

@interface CCBarGraphView ()

@property (nonatomic, strong) NSMutableArray *series;
@property (nonatomic, strong) NSMutableArray *values;

@property (nonatomic, assign) BOOL hideMarkerWhenMouseExited;
@property (nonatomic, assign) BOOL enableMarker;

@property (nonatomic, assign) NSPoint mousePoint;

@end

@implementation CCBarGraphView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _borderColor = [NSColor colorWithDeviceRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
        _highlightColor = [NSColor colorWithDeviceRed:239.0/255.0 green:239.0/255.0 blue:239.0/255.0 alpha:1.0];
        _borderWidth = 0.0;
        _barColor = [NSColor colorWithDeviceRed:5/255.0 green:141/255.0 blue:199/255.0 alpha:1.0];
        _barPeakColor = [NSColor blueColor];
        _barPeakHeight = 2.0;
        _spaceBetweenBars = 1;

        _drawAxesX = YES;
        _drawAxesY = YES;
        _drawGridX = YES;
        _drawGridY = YES;
        _gridYCount = 5;

        _highlightBar = YES;
        _drawPeaksOnly = NO;
        _drawBarWithPeak = YES;

        _series = [NSMutableArray array];
        _values = [NSMutableArray array];
        _enableMarker = YES;
    }
    
    return self;
}

- (void)draw
{
    [self.series removeAllObjects];
    [self.values removeAllObjects];

    self.series = [NSMutableArray arrayWithArray:[self.dataSource seriesForBarGraphView:self]];
    self.values = [NSMutableArray arrayWithArray:[self.dataSource valuesForBarGraphView:self]];

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

#pragma mark -> clean canvas

    [self.backgroundColor set];
    NSRectFill(rect);

#pragma mark -> draw empty

    if (self.series.count == 0) {
        [self drawAppIconForEmptyRect:rect];
        return;
    }

#pragma mark -> process data

    float minY = 0.0;
    float maxY = 0.0;
    for (NSInteger j = 0; j < self.values.count; j++) {
        if ([[self.values objectAtIndex:j] floatValue] < minY) {
            minY = [[self.values objectAtIndex:j] floatValue];
        }
        if ([[self.values objectAtIndex:j] floatValue] > maxY) {
            maxY = [[self.values objectAtIndex:j] floatValue];
        }
    }
    minY = floor(minY / 10) * 10;
    maxY = ceil(maxY / 10) * 10;
    if (maxY == minY) {
        maxY = minY + 1;
    }

    CGFloat offsetX = kOffsetX;
    CGFloat offsetY = self.drawInfo ? kOffsetYWithInfo : kOffsetY;

    CGFloat stepX = (self.frame.size.width - (offsetX * 2)) / self.series.count;
    CGFloat stepY = (rect.size.height - (offsetY * 2)) / (maxY - minY);

    CGFloat barWidth = MAX((stepX - self.spaceBetweenBars), 1);

#pragma mark -> draw axes Y and its grids

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSRightTextAlignment];
    NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                               NSFontAttributeName: self.font,
                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                               NSParagraphStyleAttributeName: paragraphStyle};

    NSInteger gridStepY = (maxY - minY) / self.gridYCount;

    for (NSInteger i = 0; i <= self.gridYCount; i++) {
        CGFloat y = (i * gridStepY) * stepY;
        float value = i * gridStepY + minY;

        if (self.drawGridY) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            CGFloat dash[] = {6.0, 6.0};
            [path setLineDash:dash count:2 phase:0.0];
            [path setLineWidth:0.1];

            NSPoint startPoint = {offsetX, y + offsetY};
            NSPoint endPoint = {rect.size.width - offsetX, y + offsetY};

            [path moveToPoint:startPoint];
            [path lineToPoint:endPoint];
            [path closePath];

            [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
            [path stroke];
        }

        if (self.drawAxesY) {
            NSString *numberString = [self.formatter stringFromNumber:[NSNumber numberWithFloat:value]];
            [numberString drawInRect:NSMakeRect(0, y + offsetY - 20/2, 50, 20) withAttributes:attsDict];
        }
    }

#pragma mark -> draw axes X and its grids

    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    attsDict = @{NSForegroundColorAttributeName: self.textColor,
                 NSFontAttributeName: self.font,
                 NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                 NSParagraphStyleAttributeName: paragraphStyle};

    NSInteger gridStepX;
    NSInteger maxStep;
    if (self.series.count > 5) {
        NSInteger stepCount = 5;
        NSInteger count = self.series.count;
        for (NSInteger i = 4; i < 10; i++) {
            if (count % i == 0) {
                stepCount = i;
            }
        }

        gridStepX = self.series.count / stepCount;
        maxStep = stepCount + 1;

    } else {
        gridStepX = 1;
        maxStep = self.series.count;
    }

    for (NSInteger i = 0; i < maxStep; i++) {
        CGFloat x = MIN(((i * gridStepX) * stepX), (self.frame.size.width - (offsetX * 2)));

        if (self.drawGridX) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            CGFloat dash[] = {6.0, 6.0};
            [path setLineDash:dash count:2 phase:0.0];
            [path setLineWidth:0.1];

            NSPoint startPoint = {x + offsetX, offsetY};
            NSPoint endPoint = {x + offsetX, rect.size.height - offsetY};

            [path moveToPoint:startPoint];
            [path lineToPoint:endPoint];
            [path closePath];

            [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
            [path stroke];
        }

        if (self.drawAxesX) {
            NSInteger index = i * gridStepX;
            if (index < self.series.count) {
                [[self.series objectAtIndex:index] drawInRect:NSMakeRect(x + offsetX + barWidth/2 - kSeriesWidth/2, offsetY/2 - kSeriesHeight/2, kSeriesWidth, kSeriesHeight) withAttributes:attsDict];
            }
        }
    }

#pragma mark -> draw graph

    CCPointInfo *pointInfo = nil;

    for (NSInteger j = 0; j < self.values.count; j++) {
        CGFloat x = j * stepX;
        CGFloat y = ([[self.values objectAtIndex:j] floatValue] - minY) * stepY;

        if (self.drawPeaksOnly || self.drawBarWithPeak) {
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(x + offsetX, y + offsetY - self.barPeakHeight, barWidth, self.barPeakHeight)];
            [self.barPeakColor set];
            [path fill];
        }

        if (!self.drawPeaksOnly) {
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(x + offsetX, offsetY, barWidth, y - self.barPeakHeight)];

            if (self.borderWidth > 0.0) {
                [path setLineWidth:self.borderWidth];
                [self.borderColor set];
                [path stroke];
            }

            BOOL highlight = NO;

            if ([path containsPoint:self.mousePoint]) {
                pointInfo = [[CCPointInfo alloc] init];
                pointInfo.x = x + offsetX + (stepX / 2);
                pointInfo.y = y + offsetY;

                if ([self.dataSource respondsToSelector:@selector(barGraphView: markerTitleForElement:)]) {
                    pointInfo.title = [self.dataSource barGraphView:self markerTitleForElement:j];
                } else {
                    pointInfo.title = [self.formatter stringFromNumber:[self.values objectAtIndex:j]];
                }

                highlight = YES;
            }

            if (highlight && self.highlightBar) {
                [self.highlightColor set];

            } else {
                [self.barColor set];
            }

            [path fill];
        }
    }

#pragma mark -> draw graph info

    if (self.drawInfo) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                                   NSFontAttributeName: self.infoFont,
                                   NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                                   NSParagraphStyleAttributeName: paragraphStyle};
        [self.info drawInRect:NSMakeRect(0, rect.size.height - kOffsetYWithInfo + 10, rect.size.width, 20) withAttributes:attsDict];
    }
    
#pragma mark -> draw marker
    
    if (self.showMarker && !self.hideMarkerWhenMouseExited && self.enableMarker && pointInfo != nil) {
        if (self.showMarker && pointInfo != nil) {
            NSPoint point = NSMakePoint(pointInfo.x, pointInfo.y);
            [self.marker drawAtPoint:point inRect:rect withTitle:pointInfo.title];
        }
    }
}

#pragma mark - event

- (void)mouseEntered:(NSEvent *)event {
    self.hideMarkerWhenMouseExited = NO;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event {
    self.hideMarkerWhenMouseExited = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint location = [event locationInWindow];
    self.mousePoint = [self convertPoint:location fromView:nil];

    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    self.enableMarker = !self.enableMarker;
    [self setNeedsDisplay:YES];
}

@end
