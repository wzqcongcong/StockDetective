//
//  CCPieView.h
//  CoreChart2D
//
//  Created by GoKu on 9/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "CCBasicView.h"

@class CCPieView;


@protocol CCPieViewDataSource <NSObject>

@required
- (NSInteger)numberOfPiePieces;
- (NSNumber *)pieView:(CCPieView *)pie valueForPiece:(NSInteger)index;
- (NSString *)pieView:(CCPieView *)pie titleForPiece:(NSInteger)index;

@optional
- (NSColor *)colorForPiePiece:(NSInteger)index;
- (NSString *)pieView:(CCPieView *)pie legendTitleForPiece:(NSString *)title withValue:(NSNumber *)value andPercent:(NSNumber *)percent;
- (NSString *)pieView:(CCPieView *)pie markerTitleForPiece:(NSString *)title withValue:(NSNumber *)value andPercent:(NSNumber *)percent;

@end

@protocol CCPieViewDelegate <NSObject>

@optional
- (void)mouseMovedAboveChartIndex:(NSInteger)index;

@end


@interface CCPieView : CCBasicView

@property (nonatomic, assign) NSInteger maxPiecesCount;
@property (nonatomic, copy) NSString *seriesNameForExceeded;

@property (nonatomic, assign) BOOL isGradient;
@property (nonatomic, assign) BOOL drawLegend;
@property (nonatomic, assign) BOOL showGuideLine;

@property (nonatomic, weak) IBOutlet id <CCPieViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id <CCPieViewDataSource> dataSource;

+ (NSColor *)colorByIndex:(NSInteger)index;
+ (NSColor *)markerColorByIndex:(NSInteger)index;

@end
