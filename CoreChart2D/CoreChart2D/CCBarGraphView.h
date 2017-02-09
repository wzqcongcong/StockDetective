//
//  CCBarGraphView.h
//  CoreChart2D
//
//  Created by GoKu on 9/6/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBasicView.h"

@class CCBarGraphView;


@protocol CCBarGraphViewDataSource <NSObject>

@required
- (NSArray *)seriesForBarGraphView:(CCBarGraphView *)graph;
- (NSArray *)valuesForBarGraphView:(CCBarGraphView *)graph;

@optional
- (NSString *)barGraphView:(CCBarGraphView *)graph markerTitleForElement:(NSInteger)elementIndex;

@end

@protocol CCBarGraphViewDelegate <NSObject>

@optional
- (void)barGraphView:(CCBarGraphView *)graph mouseMovedAboveElement:(NSInteger)index;

@end


@interface CCBarGraphView : CCBasicView

@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, strong) NSColor *highlightColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) NSColor *barColor;
@property (nonatomic, strong) NSColor *barPeakColor;
@property (nonatomic, assign) CGFloat barPeakHeight;
@property (nonatomic, assign) CGFloat spaceBetweenBars;

@property (nonatomic, assign) BOOL drawAxesX;
@property (nonatomic, assign) BOOL drawAxesY;
@property (nonatomic, assign) BOOL drawGridX;
@property (nonatomic, assign) BOOL drawGridY;
@property (nonatomic, assign) NSInteger gridYCount;

@property (nonatomic, assign) BOOL highlightBar;
@property (nonatomic, assign) BOOL drawPeaksOnly;
@property (nonatomic, assign) BOOL drawBarWithPeak;

@property (nonatomic, weak) IBOutlet id <CCBarGraphViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id <CCBarGraphViewDataSource> dataSource;

@end
