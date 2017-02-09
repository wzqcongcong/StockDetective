//
//  CCGraphView.h
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBasicView.h"

@class CCGraphView;


@protocol CCGraphViewDataSource <NSObject>

@required
- (NSInteger)numberOfGraphsInGraphView:(CCGraphView *)graph;
- (NSArray *)graphView:(CCGraphView *)graph valuesForGraph:(NSInteger)index;
- (NSArray *)seriesForGraphView:(CCGraphView *)graph;

@optional
- (NSColor *)graphView:(CCGraphView *)graph colorForGraph:(NSInteger)index;
- (NSString *)graphView:(CCGraphView *)graph legendTitleForGraph:(NSInteger)index;
- (NSString *)graphView:(CCGraphView *)graph markerTitleForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex;
- (NSView *)graphView:(CCGraphView *)graph markerViewForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex;

@end

@protocol CCGraphViewDelegate <NSObject>

@optional
- (void)graphView:(CCGraphView *)graph mouseMovedAboveElement:(NSInteger)index;

@end


@interface CCGraphView : CCBasicView

@property (nonatomic, assign) BOOL useMinValue;
@property (nonatomic, assign) float minValue;

@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, assign) BOOL drawAxesX;
@property (nonatomic, assign) BOOL drawAxesY;
@property (nonatomic, assign) BOOL drawGridX;
@property (nonatomic, assign) BOOL drawGridY;
@property (nonatomic, assign) NSInteger gridYCount;
@property (nonatomic, assign) BOOL isRoundGridY;
@property (nonatomic, assign) NSInteger roundGridYTo;

@property (nonatomic, assign) BOOL drawBaseline;
@property (nonatomic, assign) float baselineValue;

@property (nonatomic, assign) BOOL isRevert;
@property (nonatomic, assign) BOOL fillGraph;

@property (nonatomic, assign) BOOL drawLegend;

@property (nonatomic, assign) BOOL showMarkerNearPoint;

@property (nonatomic, assign) BOOL drawBullets;
@property (nonatomic, assign) BOOL highlightBullet;
@property (nonatomic, strong) CCBullet *bullet;

@property (nonatomic, assign) BOOL showMouseOverLineX;

@property (nonatomic, weak) IBOutlet id <CCGraphViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id <CCGraphViewDataSource> dataSource;

+ (NSColor *)colorByIndex:(NSInteger)index;

@end
