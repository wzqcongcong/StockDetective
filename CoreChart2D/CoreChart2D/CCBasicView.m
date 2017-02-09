//
//  CCBasicView.m
//  CoreChart2D
//
//  Created by GoKu on 9/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBasicView.h"

@interface CCBasicView ()

@property (nonatomic, strong) NSTrackingArea *trackingArea;

@end

@implementation CCBasicView

- (void)dealloc {
    [self removeTrackingArea:_trackingArea];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _formatter = [[NSNumberFormatter alloc] init];
        [_formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [_formatter setNumberStyle:NSNumberFormatterDecimalStyle];

        _font = [NSFont fontWithName:@"Helvetica Neue" size:11];
        _infoFont = [NSFont fontWithName:@"Helvetica Neue" size:12];
        _legendFont = [NSFont boldSystemFontOfSize:11];
        _backgroundColor = [NSColor colorWithDeviceRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
        _textColor = [NSColor colorWithDeviceRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];

        _drawInfo = NO;
        _info = @"";

        _showMarker = NO;
        _marker = [[CCMarker alloc] init];

        NSTrackingAreaOptions trackingOptions =	NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
        _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:trackingOptions owner:self userInfo:nil];
        [self addTrackingArea:_trackingArea];
    }
    return self;
}

- (void)draw
{

}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void)drawAppIconForEmptyRect:(NSRect)rect
{
    NSImage *appImage = [[NSApplication sharedApplication] applicationIconImage];
    CGImageRef cgImage = [appImage CGImageForProposedRect:NULL
                                                  context:[NSGraphicsContext currentContext]
                                                    hints:nil];
    CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIPointillize"
                                  keysAndValues: kCIInputImageKey, ciImage, kCIInputRadiusKey, @(2), kCIInputCenterKey, [CIVector vectorWithX:100 Y:100], nil];
    CIImage *showImage = [filter valueForKey:kCIOutputImageKey];
    [[[NSGraphicsContext currentContext] CIContext] drawImage:showImage
                                                       inRect:CGRectMake(rect.size.width / 2 - 128, rect.size.height / 2 - 128, 256, 256)
                                                     fromRect:[showImage extent]];
}

- (void)updateTrackingAreas {
    [self removeTrackingArea:_trackingArea];

    NSTrackingAreaOptions trackingOptions =	NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:trackingOptions owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

@end
