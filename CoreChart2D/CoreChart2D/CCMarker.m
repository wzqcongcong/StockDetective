//
//  CCMarker.m
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCMarker.h"

static CGFloat const kMinWidth = 40;
static CGFloat const kMinHeight = 20;

static CGFloat const kRectMarginWidth = 16;
static CGFloat const kRectMarginHeight = 8;

static CGFloat const kDrawPointOffSetY = 4;
static CGFloat const kDrawArrowOffSetY = 14;
static CGFloat const kDrawArrowSizeXY = 10;

@implementation CCMarker

- (id)init {
    self = [super init];

    if (self) {
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        _font = [fontManager fontWithFamily:@"Helvetica Neue" traits:NSBoldFontMask weight:0 size:10];
        _textColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
        _backgroundColor = [NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
        _borderColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
        _borderWidht = 2;
        _type = CCMarkerTypeRect;
        _shadow = NO;
    }

    return self;
}

- (void)drawAtPoint:(NSPoint)point inRect:(NSRect)rect withTitle:(NSString *)title {
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSDictionary *attsDict = @{NSForegroundColorAttributeName: self.textColor,
                               NSFontAttributeName: self.font,
                               NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone],
                               NSParagraphStyleAttributeName: paragraphStyle};

    NSSize labelSize = [title sizeWithAttributes:attsDict];
    CGFloat width = MAX(labelSize.width, kMinWidth);
    CGFloat height = MAX(labelSize.height, kMinHeight);
    CGFloat rectWidth = width + kRectMarginWidth;
    CGFloat rectHeight = height + kRectMarginHeight;

    switch (self.type) {
        case CCMarkerTypeRect:
            {
                NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(point.x - (rectWidth / 2), point.y + kDrawPointOffSetY, rectWidth, rectHeight)];
                [path setLineWidth:self.borderWidht];
                [self.borderColor set];
                [path stroke];
                [self.backgroundColor set];
                [path fill];

                [title drawInRect:NSMakeRect((point.x - (rectWidth / 2)) + (kRectMarginWidth / 2), point.y + kDrawPointOffSetY + (kRectMarginHeight / 2), width, height) withAttributes:attsDict];
            }
            break;

        case CCMarkerTypeRoundedRect:
            {
                NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(point.x - (rectWidth / 2), point.y + kDrawPointOffSetY, rectWidth, rectHeight) xRadius:4 yRadius:4];
                [path setLineWidth:self.borderWidht];
                [self.borderColor set];
                [path stroke];
                [self.backgroundColor set];
                [path fill];

                [title drawInRect:NSMakeRect((point.x - (rectWidth / 2)) + (kRectMarginWidth / 2), point.y + kDrawPointOffSetY + (kRectMarginHeight / 2), width, height) withAttributes:attsDict];
            }
            break;

        case CCMarkerTypeRectWithArrow:
            {
                NSBezierPath *path = [NSBezierPath bezierPath];
                [path setLineWidth:self.borderWidht];

                NSPoint drawPoint;

                CGFloat x = point.x - (rectWidth / 2);
                CGFloat y;

                BOOL downArrow = (point.y + kDrawArrowOffSetY + rectHeight < rect.size.height);

                if (downArrow) {
                    y = point.y + kDrawArrowOffSetY;

                    drawPoint.x = x;
                    drawPoint.y = y;
                    [path moveToPoint:drawPoint];

                    drawPoint.x = x;
                    drawPoint.y = y + rectHeight;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + rectWidth;
                    drawPoint.y = y + rectHeight;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + rectWidth;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + (rectWidth / 2) + kDrawArrowSizeXY;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + (rectWidth / 2);
                    drawPoint.y = y - kDrawArrowSizeXY;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + (rectWidth / 2) - kDrawArrowSizeXY;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                } else {
                    y = point.y - kDrawArrowOffSetY;

                    drawPoint.x = x;
                    drawPoint.y = y;
                    [path moveToPoint:drawPoint];

                    drawPoint.x = x;
                    drawPoint.y = y - rectHeight;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + rectWidth;
                    drawPoint.y = y - rectHeight;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + rectWidth;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + (rectWidth / 2) + kDrawArrowSizeXY;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + (rectWidth / 2);
                    drawPoint.y = y + kDrawArrowSizeXY;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x + (rectWidth / 2) - kDrawArrowSizeXY;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];

                    drawPoint.x = x;
                    drawPoint.y = y;
                    [path lineToPoint:drawPoint];
                }

                [path closePath];

                NSShadow *markerShadow = [[NSShadow alloc] init];
                if (shadow) {
                    [markerShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.66 alpha:1.0]];
                    [markerShadow setShadowBlurRadius:3];
                    [markerShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
                    [markerShadow set];
                }

                [self.borderColor set];
                [path stroke];
                [self.backgroundColor set];
                [path fill];

                if (shadow) {
                    [markerShadow setShadowColor:nil];
                    [markerShadow set];
                }		
                
                if (downArrow) {
                    [title drawInRect:NSMakeRect((point.x - (rectWidth / 2)) + (kRectMarginWidth / 2), point.y + kDrawArrowOffSetY + (kRectMarginHeight / 2), width, height) withAttributes:attsDict];
                } else {
                    [title drawInRect:NSMakeRect((point.x - (rectWidth / 2)) + (kRectMarginWidth / 2), point.y - kDrawArrowOffSetY - (kRectMarginHeight / 2) - height, width, height) withAttributes:attsDict];
                }
            }
            break;

        default:
            break;
    }
}

@end
