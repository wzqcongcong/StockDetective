//
//  SDColorBackgroundView.m
//  StockDetective
//
//  Created by GoKu on 8/1/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDColorBackgroundView.h"

#define kDefaultBackgroundColor     [NSColor whiteColor]
#define kDefaultBorderColor         [NSColor whiteColor]

@implementation SDColorBackgroundView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect
                                                         xRadius:self.sdCornerRadius
                                                         yRadius:self.sdCornerRadius];
    path.lineWidth = self.sdBorderWidth;

    NSColor *backgroundColor = self.sdBackgroundColor ? : kDefaultBackgroundColor;
    NSColor *borderColor = self.sdBorderColor ? : kDefaultBorderColor;

    [backgroundColor setFill];
    [borderColor setStroke];

    [path fill];
    [path stroke];
}

@end
