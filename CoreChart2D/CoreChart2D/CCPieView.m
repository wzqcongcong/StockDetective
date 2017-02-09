//
//  CCPieView.m
//  CoreChart2D
//
//  Created by GoKu on 9/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCPieView.h"

static CGFloat const kOffset = 20;
static CGFloat const kOffsetYWithInfo = 40;

static CGFloat const kOffsetGuideLine = 16;

@interface CCPieView ()

@property (nonatomic, strong) NSMutableArray *series;
@property (nonatomic, strong) NSMutableArray *values;
@property (nonatomic, strong) NSMutableArray *legends;

@property (nonatomic, assign) CGFloat legendWidth;

@property (nonatomic, assign) BOOL hideMarkerWhenMouseExited;
@property (nonatomic, assign) BOOL enableMarker;

@property (nonatomic, assign) NSPoint mousePoint;

@end

@implementation CCPieView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _maxPiecesCount = 10;
        _seriesNameForExceeded = @"Others";

        _isGradient = NO;
        _drawLegend = YES;
        _showGuideLine = YES;

        _series = [[NSMutableArray alloc] init];
        _values = [[NSMutableArray alloc] init];
        _legends = [[NSMutableArray alloc] init];
        _legendWidth = 0.0;
        _hideMarkerWhenMouseExited = NO;
        _enableMarker = YES;
    }
    
    return self;
}

- (void)draw
{
    [self.series removeAllObjects];
    [self.values removeAllObjects];
    [self.legends removeAllObjects];

    NSInteger count = [self.dataSource numberOfPiePieces];

    for (NSInteger i = 0; i < count; i++) {
        float value = [[self.dataSource pieView:self valueForPiece:i] floatValue];
        if (value < 0) {
            value = 0.0;
        }
        [self.values addObject:@(value)];
        [self.legends addObject:[self.dataSource pieView:self titleForPiece:i]];
    }

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

#pragma mark -> clean canvas
    
    [self.backgroundColor set];
    NSRectFill(rect);

#pragma mark -> draw empty

    if ([self.values count] == 0) {
        [self drawAppIconForEmptyRect:rect];
        return;
    }

#pragma mark -> process data

    float sum = 0.0;
    for (NSInteger i = 0; i < self.values.count; i++) {
        sum += [[self.values objectAtIndex:i] floatValue];
    }
    if (sum == 0.0) {
        [self drawAppIconForEmptyRect:rect];
        return;
    }

    CGFloat startAngle = 0.0;
    float percent = sum / 100.0;
    if (percent == 0.0) {
        percent = 1.0;
    }

    NSMutableArray *pieSeries = [NSMutableArray array];
    NSMutableArray *pieValues = [NSMutableArray array];

    if (self.maxPiecesCount == 0) {
        self.maxPiecesCount = self.values.count;
    } else {
        self.maxPiecesCount = MIN(self.maxPiecesCount, self.values.count);
    }

    for (NSInteger i = 0; i < self.maxPiecesCount; i++) {
        [pieSeries addObject:[self.legends objectAtIndex:i]];
        [pieValues addObject:[self.values objectAtIndex:i]];
    }

    if (self.values.count > self.maxPiecesCount) {
        float other = 0.0;
        for (NSInteger i = self.maxPiecesCount; i < self.values.count; i++) {
            other += [[self.values objectAtIndex:i] floatValue];
        }

        [pieSeries addObject:self.seriesNameForExceeded];
        [pieValues addObject:[NSNumber numberWithFloat:other]];
    }

#pragma mark -> draw legend

    CGFloat offsetForLegend = 0;
    if (self.drawLegend) {
        [self drawLegendInRect:rect  withSeries:(NSArray *)pieSeries];
        offsetForLegend = self.legendWidth + 12;
    }

#pragma mark -> draw pie

    CGFloat chartSpaceWidth = rect.size.width;
    CGFloat chartSpaceHeight = rect.size.height;
    if (self.drawLegend) {
        chartSpaceWidth -= offsetForLegend;
    }
    if (self.drawInfo) {
        chartSpaceHeight -= kOffsetYWithInfo;
    }

    NSPoint center = NSMakePoint(chartSpaceWidth / 2, chartSpaceHeight / 2);
    CGFloat radius = MIN(chartSpaceWidth, chartSpaceHeight) / 2 - kOffset;
    if (self.showGuideLine) {
        radius -= (kOffsetGuideLine + self.legendWidth);
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSLeftTextAlignment];
    NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                               NSFontAttributeName: self.infoFont,
                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                               NSParagraphStyleAttributeName: paragraphStyle};

    CCPointInfo *pointInfo = nil;

    for (NSInteger i = 0; i < pieValues.count; i++) {
        float percents = [[pieValues objectAtIndex:i] floatValue] / percent;
        CGFloat endAngle = startAngle + percents * 3.6;

        if (percents == 0.0) {
            continue;
        }

        NSBezierPath *path = [NSBezierPath bezierPath];
        [path setLineWidth:0.1];
        [path moveToPoint:center];
        [path appendBezierPathWithArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle];

        if ([self.dataSource respondsToSelector:@selector(colorForPiePiece:)]) {
            [[self.dataSource colorForPiePiece:i] set];
        } else {
            [[CCPieView colorByIndex:i] set];
        }

        [path fill];

        if ([path containsPoint:self.mousePoint]) {
            pointInfo = [[CCPointInfo alloc] init];
            pointInfo.x = self.mousePoint.x;
            pointInfo.y = self.mousePoint.y;

            if ([self.dataSource respondsToSelector:@selector(pieView: markerTitleForPiece: withValue: andPercent:)]) {
                pointInfo.title = [self.dataSource pieView:self markerTitleForPiece:[pieSeries objectAtIndex:i] withValue:[pieValues objectAtIndex:i] andPercent:[NSNumber numberWithFloat:percents]];
            } else {
                pointInfo.title = [NSString stringWithFormat:@"%@\n%@", [pieSeries objectAtIndex:i], [self.formatter stringFromNumber:[pieValues objectAtIndex:i]]];
            }
        }

        if (self.isGradient) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:center];
            [path appendBezierPathWithArcWithCenter:center radius:radius startAngle:0.0 endAngle:360.0];

            NSColor *color = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.15];
            NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:color endingColor:[color highlightWithLevel:0.6]];
            [gradient drawInBezierPath:path angle:90.0];
        }

#pragma mark -> draw guide line and title

        if (self.showGuideLine) {
            NSString *title = [pieSeries objectAtIndex:i];
            if ([self.dataSource respondsToSelector:@selector(pieView: legendTitleForPiece: withValue: andPercent:)]) {
                title = [self.dataSource pieView:self legendTitleForPiece:[pieSeries objectAtIndex:i] withValue:[pieValues objectAtIndex:i] andPercent:[NSNumber numberWithFloat:percents]];
            }

            NSSize labelSize = [title sizeWithAttributes:attsDict];

            CGFloat middleAngle = (endAngle - startAngle) / 2;

            NSPoint fromPoint;
            NSPoint toPoint;
            NSPoint textPoint;
            fromPoint.x = center.x + radius * cos((M_PI * (startAngle + middleAngle)) / 180.0);
            fromPoint.y = center.y + radius * sin((M_PI * (startAngle + middleAngle)) / 180.0);
            toPoint.x = center.x + (radius + kOffsetGuideLine) * cos((M_PI * (startAngle + middleAngle)) / 180.0);
            toPoint.y = center.y + (radius + kOffsetGuideLine) * sin((M_PI * (startAngle + middleAngle)) / 180.0);
            textPoint.x = center.x + (radius + kOffsetGuideLine + 2) * cos((M_PI * (startAngle + middleAngle)) / 180.0);
            textPoint.y = center.y + (radius + kOffsetGuideLine + 2) * sin((M_PI * (startAngle + middleAngle)) / 180.0);

            path = [NSBezierPath bezierPath];
            [path setLineWidth:1.0];
            [path moveToPoint:fromPoint];
            [path lineToPoint:toPoint];
            [path closePath];
            [[NSColor grayColor] set];
            [path stroke];

            CGFloat pointAngle = startAngle + middleAngle;
            CGFloat offsetX = 0.0;
            CGFloat offsetY = 0.0;
            if (pointAngle > 90 && pointAngle < 180) {
                offsetX = -labelSize.width;
                offsetY = 0;
            } else if (pointAngle >= 180 && pointAngle < 270) {
                offsetX = -labelSize.width;
                offsetY = -labelSize.height;
            } else if (pointAngle >= 270 && pointAngle <= 360) {
                offsetX = 0;
                offsetY = -labelSize.height;
            } if (pointAngle >= 0 && pointAngle <= 90) {
                offsetX = 0;
                offsetY = 0;
            }
            textPoint.x += offsetX;
            textPoint.y += offsetY;
            
            [title drawAtPoint:textPoint withAttributes:attsDict];
        }

        startAngle += percents * 3.6;
    }

#pragma mark -> draw marker

    if (self.showMarker && !self.hideMarkerWhenMouseExited && self.enableMarker && pointInfo != nil) {
        NSPoint point = NSMakePoint(pointInfo.x, pointInfo.y);
        [self.marker drawAtPoint:point inRect:rect withTitle:pointInfo.title];
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
}

#pragma mark - draw

- (void)drawLegendInRect:(NSRect)rect withSeries:(NSArray *)pieSeries
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSLeftTextAlignment];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                               NSFontAttributeName: self.legendFont,
                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                               NSParagraphStyleAttributeName: paragraphStyle};

    self.legendWidth = 0;
    for (NSInteger i = 0; i < pieSeries.count; i++) {
        NSString *legend = [pieSeries objectAtIndex:i];
        NSSize size = [legend sizeWithAttributes:attsDict];
        if (size.width > self.legendWidth) {
            self.legendWidth = size.width;
        }
    }

    CGFloat offsetY = self.drawInfo ? kOffsetYWithInfo : 0;
    CGFloat top = rect.size.height - kOffset - offsetY;

    for (NSInteger i = 0; i < pieSeries.count; i++) {
        [[CCPieView colorByIndex:i] set];
        NSRectFill(NSMakeRect(rect.size.width - self.legendWidth - kOffset - 8 + 2, top - i * 24 + 1, 8, 8));

        [[pieSeries objectAtIndex:i] drawInRect:NSMakeRect(rect.size.width - self.legendWidth - kOffset - 8 + 4 + 10, (top - i * 24) - 4, self.legendWidth, 16) withAttributes:attsDict];
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
            color = [NSColor colorWithDeviceRed:202/255.0 green:85/255.0 blue:43/255.0 alpha:1.0];
            break;
        case 3:
            color = [NSColor colorWithDeviceRed:241/255.0 green:182/255.0 blue:49/255.0 alpha:1.0];
            break;
        case 4:
            color = [NSColor colorWithDeviceRed:129/255.0 green:52/255.0 blue:79/255.0 alpha:1.0];
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

+ (NSColor *)markerColorByIndex:(NSInteger)index
{
    NSColor *color;

    switch (index) {
        case 0:
            color = [NSColor colorWithDeviceRed:5/255.0 green:141/255.0 blue:199/255.0 alpha:0.6];
            break;
        case 1:
            color = [NSColor colorWithDeviceRed:80/255.0 green:180/255.0 blue:50/255.0 alpha:0.6];
            break;
        case 2:
            color = [NSColor colorWithDeviceRed:255/255.0 green:102/255.0 blue:0/255.0 alpha:0.6];
            break;
        case 3:
            color = [NSColor colorWithDeviceRed:255/255.0 green:158/255.0 blue:1/255.0 alpha:0.6];
            break;
        case 4:
            color = [NSColor colorWithDeviceRed:252/255.0 green:210/255.0 blue:2/255.0 alpha:0.6];
            break;
        case 5:
            color = [NSColor colorWithDeviceRed:248/255.0 green:255/255.0 blue:1/255.0 alpha:0.6];
            break;
        case 6:
            color = [NSColor colorWithDeviceRed:176/255.0 green:222/255.0 blue:9/255.0 alpha:0.6];
            break;
        case 7:
            color = [NSColor colorWithDeviceRed:106/255.0 green:249/255.0 blue:196/255.0 alpha:0.6];
            break;
        case 8:
            color = [NSColor colorWithDeviceRed:178/255.0 green:222/255.0 blue:255/255.0 alpha:0.6];
            break;
        case 9:
            color = [NSColor colorWithDeviceRed:4/255.0 green:210/255.0 blue:21/255.0 alpha:0.6];
            break;
        default:
            color = [NSColor colorWithDeviceRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:0.6];
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
    NSPoint location = [event locationInWindow];
    self.mousePoint = [self convertPoint:location fromView:nil];

    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    self.enableMarker = !self.enableMarker;
    [self setNeedsDisplay:YES];
}

@end
