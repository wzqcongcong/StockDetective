//
//  SDMainWindowController.m
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import Yuba;
#import "SDMainWindowController.h"
#import "SDColorBackgroundView.h"
#import "SDGraphMarkerViewController.h"
#import "SDCommonFetcher.h"

static NSUInteger kErrorBarDurationTime     = 3;
static NSString * const kStockDataUnitWan   = @"万";

@interface SDMainWindowController ()

@property (nonatomic, strong) NSTimer *refreshDataTaskTimer;
@property (nonatomic, assign) BOOL forbiddenToRefresh;

@property (nonatomic, strong) NSString *stockDisplayInfo;
@property (nonatomic, strong) NSString *stockCode;
@property (nonatomic, assign) TaskType queryTaskType;

@property (nonatomic, strong) NSString *dataUnit;
@property (nonatomic, strong) NSArray *legend;
@property (nonatomic, strong) NSArray *series;
@property (nonatomic, strong) NSArray *values;

@property (weak) IBOutlet YBGraphView *graphView;
@property (weak) IBOutlet NSTextField *labelStockCode;
@property (weak) IBOutlet NSPopUpButton *popupGraphType;
@property (weak) IBOutlet NSButton *btnManuallyRefresh;

// error message bar
@property (weak) IBOutlet SDColorBackgroundView *errorBar;
@property (weak) IBOutlet NSLayoutConstraint *errorBarConstraint;
@property (weak) IBOutlet NSButton *btnErrorMessage;

@end

@implementation SDMainWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"SDMainWindowController"];
    if (self) {
        _stockCode = kStockCodeDaPan; // 指定具体股票时这里需要修改成相应的股票代码，例如，中国平安：000001
        _stockDisplayInfo = _stockCode;
        _queryTaskType = TaskTypeRealtime;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;

    self.errorBarConstraint.constant = -self.errorBar.frame.size.height - 2;

    [self setupGraphConfig];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self stopStockRefresher];
}

- (void)setupGraphConfig
{
    self.dataUnit = kStockDataUnitWan;
    self.legend = @[@"主力",
                    @"巨单",
                    @"大单",
                    @"中单",
                    @"小单"];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    self.graphView.formatter = formatter;
    self.graphView.drawLegend = YES;
    self.graphView.drawInfo = YES;
    self.graphView.lineWidth = 1.6;
    self.graphView.showMarker = YES;
    self.graphView.showMarkerNearPoint = NO;
    self.graphView.drawBullets = NO;
    self.graphView.useMinValue = NO;
    self.graphView.gridYCount = 10;
    self.graphView.isRoundGridY = YES;
    self.graphView.roundGridYTo = self.graphView.gridYCount * 10;
    self.graphView.drawBaseline = YES;
    self.graphView.baselineValue = 0.0;
    self.graphView.showMouseOverLineX = YES;
}

- (void)startStockRefresher
{
    if (self.forbiddenToRefresh) {
        return;
    }
    
    if (self.refreshDataTaskTimer.isValid) {
        return;
    }

    self.refreshDataTaskTimer = [NSTimer scheduledTimerWithTimeInterval:5
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
                               stockCode:self.stockCode
                          successHandler:^(NSData *data) {
                              [self updateViewWithData:data];
                          }
                          failureHandler:^(NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self showErrorMessage:@"Failed to refresh stock data"];
                              });
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

    self.graphView.info = [NSString stringWithFormat:@"%@ (%@)", self.stockDisplayInfo, array[0]];
}

#pragma mark - UI action

- (void)showErrorMessage:(NSString *)errorMessage
{
    NSLog(@"%@", errorMessage);
    self.btnErrorMessage.title = errorMessage;
    self.errorBarConstraint.animator.constant = 0;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kErrorBarDurationTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.errorBarConstraint.animator.constant = -self.errorBar.frame.size.height - 2;
    });
}

- (IBAction)btnManuallyRefreshDidClick:(id)sender {
    [self stopStockRefresher];

    NSLog(@"%@ %@", self.labelStockCode.stringValue, self.popupGraphType.selectedItem.title);

    NSString *inputStockCode = [self.labelStockCode.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.stockCode = (inputStockCode.length == 0) ? kStockCodeDaPan : inputStockCode;

    self.queryTaskType = (self.popupGraphType.indexOfSelectedItem == 0) ? TaskTypeRealtime : TaskTypeHistory;

    if ([self.stockCode isEqualToString:kStockCodeDaPan]) {
        self.stockDisplayInfo = self.stockCode;

        self.forbiddenToRefresh = NO;
        [self startStockRefresher];

    } else {
        [[SDCommonFetcher sharedSDCommonFetcher] fetchStockInfoWithCode:self.stockCode
                                                         successHandler:^(SDStockInfo *stockInfo) {
                                                             self.stockDisplayInfo = [stockInfo stockShortDisplayInfo];
                                                             // update valid stock code after query
                                                             self.stockCode = stockInfo.stockCode;

                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self.forbiddenToRefresh = NO;
                                                                 [self startStockRefresher];
                                                             });
                                                         }
                                                         failureHandler:^(NSError *error) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 self.forbiddenToRefresh = YES;
                                                                 [self showErrorMessage:@"Failed to query stock info. Invalid stock code."];
                                                             });
                                                         }];
    }
}

#pragma mark - text field delegate

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self btnManuallyRefreshDidClick:self.btnManuallyRefresh];
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

- (NSView *)graphView:(YBGraphView *)graph markerViewForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
    SDGraphMarkerViewController *graphMarkerViewController = [[SDGraphMarkerViewController alloc] init];
    graphMarkerViewController.view.hidden = NO;
    graphMarkerViewController.label.attributedStringValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld %@", [[(NSArray *)(self.values[graphIndex]) objectAtIndex:elementIndex] integerValue], self.dataUnit]
                                                                                            attributes:@{NSForegroundColorAttributeName: [YBGraphView colorByIndex:graphIndex]}];
    return graphMarkerViewController.view;
}

@end
