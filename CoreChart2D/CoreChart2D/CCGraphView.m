//
//  CCGraphView.m
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCGraphView.h"

static CGFloat const kOffsetX = 60;
static CGFloat const kOffsetY = 30;
static CGFloat const kOffsetYWithInfo = 40;

static CGFloat const kSeriesWidth = 120;
static CGFloat const kSeriesHeight = 20;

@interface CCGraphView ()

@property (nonatomic, strong) NSMutableArray *series;
@property (nonatomic, strong) NSMutableArray *graphs;
@property (nonatomic, strong) NSMutableArray *legends;
@property (nonatomic, strong) NSMutableArray *customMarkers;

@property (nonatomic, assign) float dataMinY;
@property (nonatomic, assign) float dataMaxY;
@property (nonatomic, assign) CGFloat legendWidth;

@property (nonatomic, assign) CGFloat stepX;
@property (nonatomic, assign) CGFloat stepY;

@property (nonatomic, assign) BOOL hideMarkerWhenMouseExited;
@property (nonatomic, assign) BOOL enableMarker;

@property (nonatomic, assign) BOOL enableMouseMove;
@property (nonatomic, assign) NSPoint mousePoint;

@end

@implementation CCGraphView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        _useMinValue = NO;
        _minValue = 0.0;

        _lineWidth = 1.2;

        _drawAxesX = YES;
        _drawAxesY = YES;
        _drawGridX = YES;
        _drawGridY = YES;
        _gridYCount = 5;
        _isRoundGridY = YES;
        _roundGridYTo = 10;

        _drawBaseline = NO;
        _baselineValue = 0;

        _isRevert = NO;
        _fillGraph = NO;

        _drawLegend = NO;

        _showMarkerNearPoint = NO;

        _drawBullets = NO;
        _highlightBullet = YES;
        _bullet = [[CCBullet alloc] init];

        _showMouseOverLineX = NO;

        _series = [NSMutableArray array];
        _graphs = [NSMutableArray array];
        _legends = [NSMutableArray array];
        _customMarkers = [NSMutableArray array];
        _legendWidth = 0.0;
        _enableMarker = YES;
        _enableMouseMove = YES;
    }
    
    return self;
}

- (void)setDataMinMaxY
{
    self.dataMinY = 0.0;
    self.dataMaxY = 0.0;

    for (NSInteger i = 0; i < self.graphs.count; i++) {
        NSMutableArray *values = [self.graphs objectAtIndex:i];

        if (!self.useMinValue) {
            self.dataMinY = [[values firstObject] floatValue];
        }
        self.dataMaxY = self.dataMinY;
    }

    for (NSInteger i = 0; i < self.graphs.count; i++) {
        NSMutableArray *values = [self.graphs objectAtIndex:i];

        for (NSInteger j = 0; j < values.count; j++) {
            if ([[values objectAtIndex:j] isKindOfClass:[NSNull class]]) {
                continue;
            }

            if ([[values objectAtIndex:j] floatValue] > self.dataMaxY) {
                self.dataMaxY = [[values objectAtIndex:j] floatValue];
            }

            if (!self.useMinValue) {
                if ([[values objectAtIndex:j] floatValue] < self.dataMinY) {
                    self.dataMinY = [[values objectAtIndex:j] floatValue];
                }
            }
        }
    }

    if (self.useMinValue) {
        self.dataMinY = self.minValue;
    }

    if (self.isRoundGridY) {
        self.dataMinY = floor(self.dataMinY / self.roundGridYTo) * self.roundGridYTo;
        self.dataMaxY = ceil(self.dataMaxY / self.roundGridYTo) * self.roundGridYTo;
    }

    if (self.dataMaxY == self.dataMinY) {
        self.dataMaxY = self.dataMinY + 1;
    }
}

- (void)draw
{
    [self.series removeAllObjects];
    [self.graphs removeAllObjects];
    [self.legends removeAllObjects];

    [self.series addObjectsFromArray:[self.dataSource seriesForGraphView:self]];

    NSInteger count = [self.dataSource numberOfGraphsInGraphView:self];
    for (NSInteger i = 0; i < count; i++) {
        [self.graphs addObject:[self.dataSource graphView:self valuesForGraph:i]];

        if ([self.dataSource respondsToSelector:@selector(graphView: legendTitleForGraph:)]) {
            [self.legends addObject:[self.dataSource graphView:self legendTitleForGraph:i]];
        } else {
            [self.legends addObject:@""];
        }
    }

    [self setDataMinMaxY];

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

#pragma mark -> clean canvas

    [self.backgroundColor set];
    NSRectFill(rect);

    [self cleanOldMarkers];

#pragma mark -> draw empty

    if (self.series.count == 0) {
        [self drawAppIconForEmptyRect:rect];
        return;
    }

#pragma mark -> draw legend

    CGFloat offsetForLegend = 0;
    if (self.drawLegend) {
        [self drawLegendInRect:rect];
        offsetForLegend = self.legendWidth - 4;
    }

#pragma mark -> process data

    float minY = self.dataMinY;
    float maxY = self.dataMaxY;

    CGFloat offsetX = kOffsetX;
    CGFloat offsetY = self.drawInfo ? kOffsetYWithInfo : kOffsetY;

    self.stepX = (self.frame.size.width - (offsetX * 2) - offsetForLegend) / (self.series.count - 1);
    self.stepY = (rect.size.height - (offsetY * 2)) / (maxY - minY);

#pragma mark -> draw base line

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSRightTextAlignment];
    NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                               NSFontAttributeName: self.font,
                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                               NSParagraphStyleAttributeName: paragraphStyle};

    if (self.drawBaseline) {
        CGFloat y = (self.baselineValue - minY) * self.stepY;

        if (self.drawGridY) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            CGFloat dash[] = {6.0, 6.0};
            [path setLineDash:dash count:2 phase:0];
            [path setLineWidth:1.2];

            NSPoint startPoint = NSMakePoint(offsetX, y + offsetY);
            if (self.isRevert) {
                startPoint = NSMakePoint(offsetX, rect.size.height - (y + offsetY));
            }
            NSPoint endPoint = NSMakePoint(rect.size.width - offsetX - offsetForLegend, y + offsetY);
            if (self.isRevert) {
                endPoint = NSMakePoint(rect.size.width - offsetX - offsetForLegend, rect.size.height - (y + offsetY));
            }

            [path moveToPoint:startPoint];
            [path lineToPoint:endPoint];
            [path closePath];

            [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
            [path stroke];
        }

        if (self.isRevert) {
            y = rect.size.height - (y + offsetY + 30 + 20/2);
        }

        if (self.drawAxesY) {
            NSString *numberString = [self.formatter stringFromNumber:[NSNumber numberWithFloat:self.baselineValue]];
            [numberString drawInRect:NSMakeRect(0, y + offsetY - 20/2, 50, 20) withAttributes:attsDict];
        }
    }

#pragma mark -> draw axes Y and its grids

    NSInteger gridStepY = (maxY - minY) / self.gridYCount;

    for (NSInteger i = 0; i <= self.gridYCount; i++) {
        CGFloat y = (i * gridStepY) * self.stepY;
        float value = i * gridStepY + minY;

        if (self.drawGridY) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            CGFloat dash[] = {6.0, 6.0};
            [path setLineDash:dash count:2 phase:0.0];
            [path setLineWidth:0.1];

            NSPoint startPoint = NSMakePoint(offsetX, y + offsetY);
            if (self.isRevert) {
                startPoint = NSMakePoint(offsetX, rect.size.height - (y + offsetY));
            }
            NSPoint endPoint = NSMakePoint(rect.size.width - offsetX - offsetForLegend, y + offsetY);
            if (self.isRevert) {
                endPoint = NSMakePoint(rect.size.width - offsetX - offsetForLegend, rect.size.height - (y + offsetY));
            }

            [path moveToPoint:startPoint];
            [path lineToPoint:endPoint];
            [path closePath];

            [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
            [path stroke];
        }

        if (self.isRevert) {
            y = rect.size.height - (y + offsetY + 30 + 20/2);
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
        NSInteger count = self.series.count - 1;
        NSInteger stepCount = 5;
        for (NSInteger i = 4; i < 8; i++) {
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

    if (self.series.count > 1) {
        if (self.drawGridX) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            CGFloat dash[] = {6.0, 6.0};
            [path setLineDash:dash count:2 phase:0.0];
            [path setLineWidth:0.1];

            NSPoint startPoint = NSMakePoint(offsetX, offsetY);
            NSPoint endPoint = NSMakePoint(offsetX, rect.size.height - offsetY);

            [path moveToPoint:startPoint];
            [path lineToPoint:endPoint];
            [path closePath];

            [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
            [path stroke];

            path = [NSBezierPath bezierPath];
            [path setLineDash:dash count:2 phase:0.0];
            [path setLineWidth:0.1];

            CGFloat x = self.frame.size.width - (offsetX * 2) - offsetForLegend;
            startPoint = NSMakePoint(x + offsetX, offsetY);
            endPoint = NSMakePoint(x + offsetX, rect.size.height - offsetY);

            [path moveToPoint:startPoint];
            [path lineToPoint:endPoint];
            [path closePath];

            [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
            [path stroke];
        }

        if (self.drawAxesX) {
            [[self.series objectAtIndex:0] drawInRect:NSMakeRect(offsetX - kSeriesWidth/2, offsetY/2 - kSeriesHeight/2, kSeriesWidth, kSeriesHeight) withAttributes:attsDict];
            [[self.series lastObject] drawInRect:NSMakeRect(self.frame.size.width - offsetX - offsetForLegend - kSeriesWidth/2, offsetY/2 - kSeriesHeight/2, kSeriesWidth, kSeriesHeight) withAttributes:attsDict];
        }

        for (NSInteger i = 1; i < maxStep - 1; i++) {
            CGFloat x = MIN(((i * gridStepX) * self.stepX), (self.frame.size.width - (offsetX * 2) - offsetForLegend));

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
                    [[self.series objectAtIndex:index] drawInRect:NSMakeRect(x + offsetX - kSeriesWidth/2, offsetY/2 - kSeriesHeight/2, kSeriesWidth, kSeriesHeight) withAttributes:attsDict];
                }
            }
        }

    } else {
        CGFloat x = (self.frame.size.width - (offsetX * 2) - offsetForLegend) / 2;

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
            [[self.series objectAtIndex:0] drawInRect:NSMakeRect(x + offsetX - kSeriesWidth/2, offsetY/2 - kSeriesHeight/2, kSeriesWidth, kSeriesHeight) withAttributes:attsDict];
        }
    }

#pragma mark -> draw graph

    NSMutableArray *markers = [NSMutableArray array];

    NSInteger mouseMovedSeriesLinePointIndex = -1;
    CGFloat mouseMovedSeriesLinePosition = 0;

    NSPoint lastPoint = NSZeroPoint;

    for (NSInteger i = 0; i < self.graphs.count; i++) {
        NSMutableArray *values = [self.graphs objectAtIndex:i];
        NSColor *color = [NSColor clearColor];

        BOOL alreadyAddTheMarkerForCurrentGraph = NO;

        if (values.count == 1) {
            CGFloat x = (self.frame.size.width - offsetForLegend) / 2;
            CGFloat y = [[values objectAtIndex:0] floatValue] * self.stepY;
            if (!self.useMinValue) {
                y = ([[values objectAtIndex:0] floatValue] - minY) * self.stepY;
            }

            NSPoint point = NSMakePoint(x, y);
            if (self.isRevert) {
                point = NSMakePoint(x,  rect.size.height - (y + offsetY));
            }

            self.bullet.color = [CCGraphView colorByIndex:i];
            [self.bullet drawAtPoint:point];

            lastPoint = point;

        } else {
            NSMutableArray *points = [NSMutableArray array];

            for (NSInteger j = 0; j < values.count - 1; j++) {
                if ([[values objectAtIndex:j] isKindOfClass:[NSNull class]]) {
                    continue;
                }

                CGFloat x = j * self.stepX;
                CGFloat y = 0;

                if (self.useMinValue) {
                    float value = [[values objectAtIndex:j] floatValue];
                    if (value < self.minValue) {
                        value = self.minValue;
                    }
                    y = value * self.stepY;

                } else {
                    y = ([[values objectAtIndex:j] floatValue] - minY) * self.stepY;
                }

                NSBezierPath *path = [NSBezierPath bezierPath];
                [path setLineWidth:self.lineWidth];

                NSPoint startPoint = NSMakePoint(x + offsetX, y + offsetY);
                if (self.isRevert) {
                    startPoint = NSMakePoint(x + offsetX, rect.size.height - (y + offsetY));
                }

                if ([[values objectAtIndex:j + 1] isKindOfClass:[NSNull class]]) {
                    [path moveToPoint:startPoint];
                    [path lineToPoint:startPoint];
                    [path closePath];

                    if ([self.dataSource respondsToSelector:@selector(graphView: colorForGraph:)]) {
                        color = [self.dataSource graphView:self colorForGraph:i];
                    } else {
                        color = [CCGraphView colorByIndex:i];
                    }

                    [color set];
                    [path stroke];

                    lastPoint = startPoint;

                    if (self.drawBullets) {
                        self.bullet.color = [CCGraphView colorByIndex:i];
                        [self.bullet drawAtPoint:startPoint];
                    }

                    if (self.mousePoint.x > startPoint.x - (self.stepX / 2) && self.mousePoint.x < startPoint.x + (self.stepX / 2)) {
                        CCPointInfo *pointInfo = [[CCPointInfo alloc] init];
                        pointInfo.x = startPoint.x;
                        pointInfo.y = startPoint.y;

                        if ([self.dataSource respondsToSelector:@selector(graphView: markerTitleForGraph: forElement:)]) {
                            pointInfo.title = [self.dataSource graphView:self markerTitleForGraph:i forElement:j];
                        } else {
                            pointInfo.title = [self.formatter stringFromNumber:[[self.graphs objectAtIndex:i] objectAtIndex:j]];
                        }

                        if (!alreadyAddTheMarkerForCurrentGraph) {
                            alreadyAddTheMarkerForCurrentGraph = YES;
                            [markers addObject:pointInfo];

                            mouseMovedSeriesLinePointIndex = j;
                            mouseMovedSeriesLinePosition = pointInfo.x;
                        }
                    }

                    continue;
                }

                x = (j + 1) * self.stepX;

                if (self.useMinValue) {
                    float value = [[values objectAtIndex:j + 1] floatValue];
                    if (value < self.minValue) {
                        value = self.minValue;
                    }
                    y = value * self.stepY;

                } else {
                    y = ([[values objectAtIndex:j + 1] floatValue] - minY) * self.stepY;
                }

                NSPoint endPoint = NSMakePoint(x + offsetX, y + offsetY);
                if (self.isRevert) {
                    endPoint = NSMakePoint(x + offsetX, rect.size.height - (y + offsetY));
                }

                [path moveToPoint:startPoint];
                [path lineToPoint:endPoint];
                [path closePath];

                if ([self.dataSource respondsToSelector:@selector(graphView: colorForGraph:)]) {
                    color = [self.dataSource graphView:self colorForGraph:i];
                } else {
                    color = [CCGraphView colorByIndex:i];
                }

                [color set];
                [path stroke];

                [points addObject:[NSValue valueWithPoint:startPoint]];

                BOOL isHighlighted = NO;

                CCPointInfo *pointInfo = [self infoForPoint:startPoint graphIndex:i elementIndex:j];
                if (pointInfo) {
                    if (!alreadyAddTheMarkerForCurrentGraph) {
                        alreadyAddTheMarkerForCurrentGraph = YES;
                        [markers addObject:pointInfo];
                        isHighlighted = YES;

                        mouseMovedSeriesLinePointIndex = j;
                        mouseMovedSeriesLinePosition = pointInfo.x;
                    }
                }

                if (self.drawBullets) {
                    if (!self.highlightBullet || !self.enableMarker) {
                        isHighlighted = NO;
                    }
                    self.bullet.color = [CCGraphView colorByIndex:i];
                    [self.bullet drawAtPoint:startPoint highlighted:isHighlighted];

                } else if (self.highlightBullet && isHighlighted && self.enableMarker) {
                    self.bullet.color = [CCGraphView colorByIndex:i];
                    [self.bullet drawAtPoint:startPoint highlighted:NO];
                }

                lastPoint = endPoint;
            }

            if (self.fillGraph && values.count > 1) {
                NSPoint startPoint = [[points objectAtIndex:0] pointValue];
                [points addObject:[NSValue valueWithPoint:lastPoint]];
                [points addObject:[NSValue valueWithPoint:NSMakePoint(lastPoint.x, offsetY)]];
                [points addObject:[NSValue valueWithPoint:NSMakePoint(startPoint.x, offsetY)]];
                [points addObject:[NSValue valueWithPoint:NSMakePoint(offsetX, offsetY)]];
                [points addObject:[NSValue valueWithPoint:startPoint]];

                NSBezierPath *path = [NSBezierPath bezierPath];
                [path setLineWidth:0.0];
                NSPoint point = [[points objectAtIndex:0] pointValue];
                if (point.y < offsetY) {
                    point.y = offsetY;
                }
                [path moveToPoint:point];

                for (NSInteger i = 1; i < points.count; i++) {
                    point = [[points objectAtIndex:i] pointValue];
                    if (point.y < offsetY) {
                        point.y = offsetY;
                    }
                    [path lineToPoint:point];
                }

                [path closePath];
                [[color colorWithAlphaComponent:0.2] set];
                [path fill];
            }
        }

        BOOL isHighlighted = NO;

        CCPointInfo *pointInfo = [self infoForPoint:lastPoint graphIndex:i elementIndex:(values.count - 1)];
        if (pointInfo) {
            if (!alreadyAddTheMarkerForCurrentGraph) {
                alreadyAddTheMarkerForCurrentGraph = YES;
                [markers addObject:pointInfo];
                isHighlighted = alreadyAddTheMarkerForCurrentGraph;

                mouseMovedSeriesLinePointIndex = values.count - 1;
                mouseMovedSeriesLinePosition = pointInfo.x;
            }
        }

        if (self.drawBullets) {
            if (!self.highlightBullet || !self.enableMarker) {
                isHighlighted = NO;
            }
            self.bullet.color = [CCGraphView colorByIndex:i];
            [self.bullet drawAtPoint:lastPoint highlighted:isHighlighted];

        } else if (self.highlightBullet && isHighlighted && self.enableMarker) {
            self.bullet.color = [CCGraphView colorByIndex:i];
            [self.bullet drawAtPoint:lastPoint highlighted:NO];
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

#pragma mark -> draw mouse over line

    if (self.highlightBullet) {
        if (mouseMovedSeriesLinePointIndex > -1) {
            [[self.series objectAtIndex:mouseMovedSeriesLinePointIndex] drawInRect:NSMakeRect(mouseMovedSeriesLinePosition - kSeriesWidth/2, offsetY/2, kSeriesWidth, kSeriesHeight) withAttributes:attsDict];

            if (self.showMouseOverLineX) {
                NSBezierPath *path = [NSBezierPath bezierPath];
                CGFloat dash[] = {1.0, 1.0};
                [path setLineDash:dash count:2 phase:0.5];
                [path setLineWidth:0.2];
                
                NSPoint startPoint = {mouseMovedSeriesLinePosition, offsetY};
                NSPoint endPoint = {mouseMovedSeriesLinePosition, rect.size.height - offsetY};
                [path moveToPoint:startPoint];
                [path lineToPoint:endPoint];
                
                [path closePath];
                [[NSColor colorWithDeviceRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] set];
                [path stroke];
            }
            
            // update legend based on mouse over data
            if (self.drawLegend) {
                NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [paragraphStyle setAlignment:NSLeftTextAlignment];
                [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

                for (NSInteger i = 0; i < self.legends.count; i++) {
                    CGFloat top = rect.size.height - offsetY - 10;
                    NSDictionary *attsDict = @{NSForegroundColorAttributeName: [CCGraphView colorByIndex:i],
                                               NSFontAttributeName: self.legendFont,
                                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                                               NSParagraphStyleAttributeName: paragraphStyle};
                    NSString *legendValue = [NSString stringWithFormat:@"%@", [[self.graphs objectAtIndex:i] objectAtIndex:mouseMovedSeriesLinePointIndex]];
                    [legendValue drawInRect:NSMakeRect(rect.size.width - self.legendWidth - (offsetX - 8) + 4 + 10, (top - i * 32) - 18, [legendValue sizeWithAttributes:attsDict].width, 16) withAttributes:attsDict];
                }
            }
        }
    }

#pragma mark -> draw markers

    [self drawMarkers:markers inRect:rect];
}

#pragma mark - draw

- (void)cleanOldMarkers
{
    for (NSView *view in self.customMarkers) {
        [view removeFromSuperview];
    }
    [self.customMarkers removeAllObjects];
}

- (void)drawLegendInRect:(NSRect)rect
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSLeftTextAlignment];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                               NSFontAttributeName: self.legendFont,
                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                               NSParagraphStyleAttributeName: paragraphStyle};

    self.legendWidth = 0;
    for (NSInteger i = 0; i < self.legends.count; i++) {
        NSString *legend = [self.legends objectAtIndex:i];
        NSSize size = [legend sizeWithAttributes:attsDict];
        if (size.width > self.legendWidth) {
            self.legendWidth = size.width;
        }
    }

    CGFloat offsetY = self.drawInfo ? kOffsetYWithInfo : kOffsetY;
    CGFloat top = rect.size.height - offsetY - 10;

    for (NSInteger i = 0; i < self.legends.count; i++) {
        [[CCGraphView colorByIndex:i] set];
        NSRectFill(NSMakeRect(rect.size.width - self.legendWidth - (kOffsetX - 8) + 2, top - i * 32 + 1, 8, 8));

        [[self.legends objectAtIndex:i] drawInRect:NSMakeRect(rect.size.width - self.legendWidth - (kOffsetX - 8) + 4 + 10, (top - i * 32) - 4, self.legendWidth, 16) withAttributes:attsDict];
    }
}

- (void)drawCustomView:(NSView *)customView atPoint:(NSPoint)point inRect:(NSRect)rect
{
    NSSize size = customView.bounds.size;
    CGFloat offsetY = (point.y + size.height > rect.size.height) ? (-size.height - 4) : 4;

    [customView setFrameOrigin:NSMakePoint(point.x - (size.width / 2), point.y + offsetY)];
    [self addSubview:customView];
}

- (void)drawMarkers:(NSArray *)markers inRect:(NSRect)rect
{
    if (self.showMarker && !self.hideMarkerWhenMouseExited && self.enableMarker) {
        [self cleanOldMarkers];

        for (CCPointInfo *pointInfo in markers) {
            NSPoint point = NSMakePoint(pointInfo.x, pointInfo.y);

            if ([self.dataSource respondsToSelector:@selector(graphView: markerViewForGraph: forElement:)]) {
                NSView *customMarker = [self.dataSource graphView:self markerViewForGraph:pointInfo.graph forElement:pointInfo.element];
                [self drawCustomView:customMarker atPoint:point inRect:rect];
                [self.customMarkers addObject:customMarker];

            } else {
                [self.marker drawAtPoint:point inRect:rect withTitle:pointInfo.title];
            }
        }
    }
}

- (CCPointInfo *)infoForPoint:(NSPoint)point graphIndex:(NSInteger)graphIndex elementIndex:(NSInteger)elementIndex
{
    BOOL validPoint = NO;

    if (self.showMarkerNearPoint) {
        if (self.mousePoint.x > point.x - (self.stepX / 2) && self.mousePoint.x < point.x + (self.stepX / 2) &&
            self.mousePoint.y > point.y - (self.stepY / 2) && self.mousePoint.y < point.y + (self.stepY / 2)) {
            validPoint = YES;
        }

    } else {
        if (self.mousePoint.x > point.x - (self.stepX / 2) && self.mousePoint.x < point.x + (self.stepX / 2)) {
            validPoint = YES;
        }
    }

    if (validPoint) {
        CCPointInfo *pointInfo = [[CCPointInfo alloc] init];
        pointInfo.x = point.x;
        pointInfo.y = point.y;
        pointInfo.graph = graphIndex;
        pointInfo.element = elementIndex;

        if ([self.dataSource respondsToSelector:@selector(graphView: markerTitleForGraph: forElement:)]) {
            pointInfo.title = [self.dataSource graphView:self markerTitleForGraph:graphIndex forElement:elementIndex];
        } else {
            pointInfo.title = [self.formatter stringFromNumber:[[self.graphs objectAtIndex:graphIndex] objectAtIndex:elementIndex]];
        }

        return pointInfo;

    } else {
        return nil;
    }
}

+ (NSColor *)colorByIndex:(NSInteger)index
{
    NSColor *color;

    switch (index) {
        case 0:
            color = [NSColor colorWithDeviceRed:1/255.0 green:165/255.0 blue:218/255.0 alpha:1.0];
            break;
        case 1:
            color = [NSColor colorWithDeviceRed:122/255.0 green:184/255.0 blue:37/255.0 alpha:1.0];
            break;
        case 2:
            color = [NSColor colorWithDeviceRed:162/255.0 green:85/255.0 blue:43/255.0 alpha:1.0];
            break;
        case 3:
            color = [NSColor colorWithDeviceRed:241/255.0 green:222/255.0 blue:49/255.0 alpha:1.0];
            break;
        case 4:
            color = [NSColor colorWithDeviceRed:255/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
            break;
        case 5:
            color = [NSColor colorWithDeviceRed:248/255.0 green:255/255.0 blue:1/255.0 alpha:1.0];
            break;
        case 6:
            color = [NSColor colorWithDeviceRed:176/255.0 green:222/255.0 blue:9/255.0 alpha:1.0];
            break;
        case 7:
            color = [NSColor colorWithDeviceRed:106/255.0 green:249/255.0 blue:196/255.0 alpha:1.0];
            break;
        case 8:
            color = [NSColor colorWithDeviceRed:178/255.0 green:222/255.0 blue:255/255.0 alpha:1.0];
            break;
        case 9:
            color = [NSColor colorWithDeviceRed:4/255.0 green:210/255.0 blue:21/255.0 alpha:1.0];
            break;
        default:
            color = [NSColor colorWithDeviceRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
            break;
    }

    return color;
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
    if (self.enableMouseMove) {
        NSPoint location = [event locationInWindow];
        self.mousePoint = [self convertPoint:location fromView:nil];

        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDown:(NSEvent *)event {
    self.enableMouseMove = !self.enableMouseMove;
    [self mouseMoved:event];
}

@end
