//
//  TodayViewController.m
//  ExtensionToday
//
//  Created by GoKu on 8/10/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import Yuba;
#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "SDCommonFetcher.h"
//#import "LogFormatter.h"

static NSUInteger const kDataRefreshInterval  = 5;

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, strong) NSTimer *refreshDataTaskTimer;
@property (nonatomic, assign) BOOL forbiddenToRefresh;

@property (nonatomic, strong) NSString *inputStockCode; // stock code or pinyin abbr.
@property (nonatomic, assign) TaskType queryTaskType;
@property (nonatomic, strong) SDStockInfo *stockInfo;

@property (nonatomic, strong) NSString *dataUnit;
@property (nonatomic, strong) NSArray *legend;
@property (nonatomic, strong) NSArray *series;
@property (nonatomic, strong) NSArray *values;

@property (atomic, assign) BOOL needToReshowBoard;
@property (weak) IBOutlet NSTextField *titleStock;
@property (weak) IBOutlet NSTextField *titlePrice;
@property (weak) IBOutlet YBGraphView *graphView;
@property (weak) IBOutlet NSLayoutConstraint *constraintGraph;

@end

@implementation TodayViewController

- (void)awakeFromNib
{
    self.inputStockCode = kSDStockDaPanFullCode; // specific stock should use its own stock code without type, like 平安银行 uses "000001".
    self.queryTaskType = TaskTypeRealtime;
    self.stockInfo = [[SDStockInfo alloc] initDaPan];
}

- (void)viewDidLoad
{
    [self setupGraphConfig];
}

- (void)setupGraphConfig
{
    self.legend = @[@"主力",
                    @"巨单",
                    @"大单",
                    @"中单",
                    @"小单"];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    self.graphView.backgroundColor = [NSColor clearColor];
    self.graphView.textColor = [NSColor labelColor];
    self.graphView.formatter = formatter;
    self.graphView.drawLegend = YES;
    self.graphView.drawInfo = YES;
    self.graphView.lineWidth = 1.6;
    self.graphView.showMarker = NO;
    self.graphView.showMarkerNearPoint = NO;
    self.graphView.drawBullets = NO;
    self.graphView.highlightBullet = NO;
    self.graphView.useMinValue = NO;
    self.graphView.gridYCount = 10;
    self.graphView.isRoundGridY = YES;
    self.graphView.roundGridYTo = self.graphView.gridYCount * 10;
    self.graphView.drawBaseline = YES;
    self.graphView.baselineValue = 0.0;
    self.graphView.showMouseOverLineX = NO;
}

- (void)manuallyUpdateWidget
{
    self.needToReshowBoard = YES;
    [self stopStockRefresher];

    self.inputStockCode = kSDStockDaPanFullCode;
    self.queryTaskType = TaskTypeRealtime;

    if ([self.inputStockCode isEqualToString:kSDStockDaPanFullCode]) {
        self.stockInfo = [[SDStockInfo alloc] initDaPan];

        self.forbiddenToRefresh = NO;
        [self startStockRefresher];

    } else {

        [[SDCommonFetcher sharedSDCommonFetcher] fetchStockInfoWithCode:self.inputStockCode
                                                         successHandler:^(SDStockInfo *stockInfo) {
                                                             self.stockInfo = stockInfo;
                                                             // update valid stock code after query
                                                             self.inputStockCode = self.stockInfo.stockCode;

                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self.forbiddenToRefresh = NO;
                                                                 [self startStockRefresher];
                                                             });
                                                         }
                                                         failureHandler:^(NSError *error) {
                                                         }];
    }
}

- (void)startStockRefresher
{
    if (self.forbiddenToRefresh) {
        return;
    }

    if (self.refreshDataTaskTimer.isValid) {
        return;
    }

    self.refreshDataTaskTimer = [NSTimer scheduledTimerWithTimeInterval:kDataRefreshInterval
                                                                 target:self
                                                               selector:@selector(doRefreshDataTask)
                                                               userInfo:nil
                                                                repeats:YES];
    [self.refreshDataTaskTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
}

- (void)stopStockRefresher
{
    [self.refreshDataTaskTimer invalidate];
}

- (void)doRefreshDataTask
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SDRefreshDataTask *refreshDataTask = [[SDRefreshDataTask alloc] init];
        refreshDataTask.taskManager = self;
        [refreshDataTask refreshDataTask:self.queryTaskType
                               stockCode:self.inputStockCode
                          successHandler:^(NSData *data) {
                              [self updateViewWithData:data];
                          }
                          failureHandler:^(NSError *error) {
                          }];
    });

    // query stock market
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SDCommonFetcher sharedSDCommonFetcher] fetchStockMarketWithStockInfo:self.stockInfo
                                                                successHandler:^(SDStockMarket *stockMarket) {
//                                                                    DDLogDebug(@"%@", [stockMarket currentPriceDescription]);

                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        self.titleStock.stringValue = self.stockInfo.stockName;
                                                                        self.titlePrice.stringValue = [stockMarket currentPriceWithPercentage];

                                                                        if (stockMarket.changePercentage.floatValue > 0) {
                                                                            self.titlePrice.textColor = [NSColor redColor];
                                                                        } else if (stockMarket.changePercentage.floatValue < 0) {
                                                                            self.titlePrice.textColor = [NSColor greenColor];
                                                                        } else {
                                                                            self.titlePrice.textColor = [NSColor labelColor];
                                                                        }

                                                                        self.needToReshowBoard = NO;
                                                                    });
                                                                }
                                                                failureHandler:^(NSError *error) {
                                                                }];
    });
}

- (void)updateViewWithData:(NSData *)data
{
    if (!data) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self parseData:data];
        [self.graphView draw];
    });

    // if stock market is not yet queried back at this time, set the board status to undefined, waiting new stock market data updates it to normal.
    if (self.needToReshowBoard) {
        self.titleStock.stringValue = @"?.?";
        self.titlePrice.stringValue = @"?.?";
    }
}

- (void)parseData:(NSData *)data
{
    self.series = nil;
    self.values = nil;

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *array = [string componentsSeparatedByString:@"\r\n"];

    NSMutableArray *seriesLabel = [NSMutableArray array];
    NSMutableArray *mainForce = [NSMutableArray array];
    NSMutableArray *superForce = [NSMutableArray array];
    NSMutableArray *bigForce = [NSMutableArray array];
    NSMutableArray *mediumForce = [NSMutableArray array];
    NSMutableArray *littleForce = [NSMutableArray array];

    for (NSString *subString in array) {
        if ([subString containsString:@";"]) {
            NSArray *subArray = [subString componentsSeparatedByString:@";"];
            [seriesLabel addObject:subArray[0]];
            [mainForce addObject:@([((NSString *)(subArray[1])) integerValue])];
            [superForce addObject:@([((NSString *)(subArray[2])) integerValue])];
            [bigForce addObject:@([((NSString *)(subArray[3])) integerValue])];
            [mediumForce addObject:@([((NSString *)(subArray[4])) integerValue])];
            [littleForce addObject:@([((NSString *)(subArray[5])) integerValue])];
        }
    }

    self.series = seriesLabel;
    self.values = @[mainForce,
                    superForce,
                    bigForce,
                    mediumForce,
                    littleForce];

    self.graphView.info = [NSString stringWithFormat:@"%@ (%@)", [self.stockInfo stockShortDisplayInfo], array[0]];
}

#pragma mark - ui action

- (IBAction)btnTitleBackground:(id)sender
{
    if (self.constraintGraph.constant == 0) {
        self.constraintGraph.animator.constant = -self.graphView.frame.size.height;
    } else {
        self.constraintGraph.animator.constant = 0;
    }
}

#pragma mark - graph view delegate

- (NSInteger)numberOfGraphsInGraphView:(YBGraphView *)graph {
    return self.values.count;
}

- (NSArray *)seriesForGraphView:(YBGraphView *)graph {
    return self.series;
}

- (NSArray *)graphView:(YBGraphView *)graph valuesForGraph:(NSInteger)index {
    return (NSArray *)(self.values[index]);
}

- (NSString *)graphView:(YBGraphView *)graph legendTitleForGraph:(NSInteger)index
{
    return self.legend[index];
}

- (NSString *)graphView:(YBGraphView *)graph markerTitleForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
    return [NSString stringWithFormat:@"%ld %@", [[(NSArray *)(self.values[graphIndex]) objectAtIndex:elementIndex] integerValue], self.dataUnit];
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    // Update your data and prepare for a snapshot. Call completion handler when you are done
    // with NoData if nothing has changed or NewData if there is new data since the last
    // time we called you
    [self manuallyUpdateWidget];

    completionHandler(NCUpdateResultNoData);
}

- (NSEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(NSEdgeInsets)defaultMarginInset {
    // Override the left margin so that the list view is flush with the edge.
    defaultMarginInset.left = 0;
    return defaultMarginInset;
}

@end

