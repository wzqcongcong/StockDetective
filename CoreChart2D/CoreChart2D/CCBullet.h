//
//  CCBullet.h
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    CCBulletTypeCircle = 0,
    CCBulletTypeSquare,
} CCBulletType;

@interface CCBullet : NSObject

@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, assign) CGFloat size;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CCBulletType type;
@property (nonatomic, assign) BOOL isHighlighted;

- (void)drawAtPoint:(NSPoint)point;
- (void)drawAtPoint:(NSPoint)point highlighted:(BOOL)highlighted;

@end
