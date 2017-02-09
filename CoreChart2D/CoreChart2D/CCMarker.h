//
//  CCMarker.h
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    CCMarkerTypeRect = 0,
    CCMarkerTypeRoundedRect,
    CCMarkerTypeRectWithArrow,
} CCMarkerType;

@interface CCMarker : NSObject

@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSColor *textColor;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidht;
@property (nonatomic, assign) CCMarkerType type;
@property (nonatomic, assign) BOOL shadow;

- (void)drawAtPoint:(NSPoint)point inRect:(NSRect)rect withTitle:(NSString *)title;

@end
