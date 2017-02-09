//
//  CCBullet.m
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBullet.h"

@implementation CCBullet

- (id)init {
    self = [super init];

    if (self) {
        _color = [NSColor blackColor];
        _borderColor = [NSColor whiteColor];
        _size = 6;
        _borderWidth = 2;
        _type = CCBulletTypeCircle;
        _isHighlighted = NO;
    }

    return self;
}


- (void)drawAtPoint:(NSPoint)point {
    [self drawAtPoint:point highlighted:self.isHighlighted];
}

- (void)drawAtPoint:(NSPoint)point highlighted:(BOOL)highlighted {
    CGFloat theSize = self.size;

    if (highlighted) {
        theSize *= 1.5;
    }

    switch (self.type) {
        case CCBulletTypeCircle:
            {
                NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - (theSize / 2), point.y - (theSize / 2), theSize, theSize)];
                [path setLineWidth:self.borderWidth];
                [path closePath];
                [self.borderColor set];
                [path stroke];
                [self.color set];
                [path fill];
            }
            break;

        case CCBulletTypeSquare:
            {
                NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(point.x - (theSize / 2), point.y - (theSize / 2), theSize, theSize)];
                [path setLineWidth:self.borderWidth];
                [path closePath];
                [self.borderColor set];
                [path stroke];
                [self.color set];
                [path fill];
            }
            break;

        default:
            break;
    }
}

@end
