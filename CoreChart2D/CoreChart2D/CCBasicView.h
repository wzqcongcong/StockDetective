//
//  CCBasicView.h
//  CoreChart2D
//
//  Created by GoKu on 9/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import QuartzCore;
#import <Cocoa/Cocoa.h>
#import "CCMarker.h"
#import "CCBullet.h"
#import "CCPointInfo.h"

@interface CCBasicView : NSView

@property (nonatomic, strong) NSNumberFormatter *formatter;

@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSFont *infoFont;
@property (nonatomic, strong) NSFont *legendFont;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *textColor;

@property (nonatomic, assign) BOOL drawInfo;
@property (nonatomic, copy) NSString *info;

@property (nonatomic, assign) BOOL showMarker;
@property (nonatomic, strong) CCMarker *marker;

- (void)draw;

- (void)drawAppIconForEmptyRect:(NSRect)rect;

@end
