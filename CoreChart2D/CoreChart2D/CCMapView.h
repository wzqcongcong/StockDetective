//
//  CCMapView.h
//  CoreChart2D
//
//  Created by GoKu on 9/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBasicView.h"

@class CCMapView;


@protocol CCMapViewDataSource <NSObject>

@required
- (NSNumber *)mapView:(CCMapView *)map valueForCountry:(NSString *)code;

@optional
- (NSString *)mapView:(CCMapView *)map markerTitleForCountry:(NSString *)code;

@end

@protocol CCMapViewDelegate <NSObject>

@optional
- (void)mapView:(CCMapView *)map mouseMovedAboveCountry:(NSString *)code;

@end


@interface CCMapView : CCBasicView

@property (nonatomic, strong) NSColor *maxColor;
@property (nonatomic, strong) NSColor *zeroColor;
@property (nonatomic, strong) NSColor *highlightColor;

@property (nonatomic, weak) IBOutlet id <CCMapViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id <CCMapViewDataSource> dataSource;

- (void)highlightCountry:(NSString *)code inRect:(NSRect)rect;
- (NSColor *)colorForValue:(float)value;

@end
