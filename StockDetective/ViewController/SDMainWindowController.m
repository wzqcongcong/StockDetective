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
#import <pop/POP.h>

static NSUInteger const kDataRefreshInterval  = 5;
static NSUInteger const kErrorBarDurationTime = 3;
static NSString * const kStockDataUnitWan     = @"万";

@interface SDMainWindowController ()

@property (nonatomic, strong) NSTimer *refreshDataTaskTimer;
@property (nonatomic, assign) BOOL forbiddenToRefresh;

@property (nonatomic, strong) NSString *inputStockCode; // stock code or pinyin abbr.
@property (nonatomic, assign) TaskType queryTaskType;
@property (nonatomic, strong) SDStockInfo *stockInfo;

@property (nonatomic, strong) NSString *dataUnit;
@property (nonatomic, strong) NSArray *legend;
@property (nonatomic, strong) NSArray *series;
@property (nonatomic, strong) NSArray *values;

// header
@property (weak) IBOutlet SDColorBackgroundView *headerBar;
@property (weak) IBOutlet NSTextField *labelStockCode;
@property (weak) IBOutlet NSPopUpButton *popupGraphType;
@property (weak) IBOutlet NSButton *btnManuallyRefresh;
@property (weak) IBOutlet NSProgressIndicator *progressForQuery;

// board
@property (atomic, assign) BOOL needToReshowBoard;
@property (weak) IBOutlet NSView *leftBoard;
@property (weak) IBOutlet NSTextField *leftBoardLabel;
@property (weak) IBOutlet NSTextField *leftBoardSubLabel;
@property (weak) IBOutlet NSLayoutConstraint *leftBoardConstraint;
@property (weak) IBOutlet NSView *rightBoard;
@property (weak) IBOutlet NSTextField *rightBoardLabel;
@property (weak) IBOutlet NSTextField *rightBoardSubLabel;
@property (weak) IBOutlet NSLayoutConstraint *rightBoardConstraint;

// graph
@property (weak) IBOutlet YBGraphView *graphView;

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
        _inputStockCode = kSDStockDaPanFullCode; // specific stock should use its own stock code without type, like 平安银行 uses "000001".
        _queryTaskType = TaskTypeRealtime;
        _stockInfo = [[SDStockInfo alloc] initDaPan];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;

    self.errorBar.hidden = NO;
    self.errorBarConstraint.constant = -self.errorBar.frame.size.height - 2;
    self.leftBoardConstraint.constant = -self.leftBoard.frame.size.height;
    self.rightBoardConstraint.constant = -self.rightBoard.frame.size.height;
    self.leftBoardLabel.stringValue = @"-.-";
    self.leftBoardSubLabel.stringValue = @"";
    self.rightBoardLabel.stringValue = @"-.-";
    self.rightBoardSubLabel.stringValue = @"";

    self.needToReshowBoard = YES;

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
    self.graphView.highlightBullet = YES;
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
    [self busyWithQuery:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SDRefreshDataTask *refreshDataTask = [[SDRefreshDataTask alloc] init];
        refreshDataTask.taskManager = self;
        [refreshDataTask refreshDataTask:self.queryTaskType
                               stockCode:self.inputStockCode
                          successHandler:^(NSData *data) {
                              [self updateViewWithData:data];
                          }
                          failureHandler:^(NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self busyWithQuery:NO];
                                  [self showErrorMessage:@"Failed to refresh stock data"];
                              });
                          }];
    });

    // query stock market
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SDCommonFetcher sharedSDCommonFetcher] fetchStockMarketWithStockInfo:self.stockInfo
                                                                successHandler:^(SDStockMarket *stockMarket) {
                                                                    NSLog(@"%@", [stockMarket currentPriceDescription]);
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        self.leftBoardLabel.stringValue = self.stockInfo.stockName;
                                                                        self.leftBoardSubLabel.stringValue = [self.stockInfo fullStockCode];
                                                                        self.rightBoardLabel.stringValue = stockMarket.currentPrice;
                                                                        self.rightBoardSubLabel.stringValue = [stockMarket.changePercentage stringByAppendingString:@"%"];

                                                                        if (stockMarket.changePercentage.floatValue > 0) {
                                                                            self.rightBoardLabel.textColor = [NSColor redColor];
                                                                            self.rightBoardSubLabel.textColor = [NSColor redColor];
                                                                        } else if (stockMarket.changePercentage.floatValue < 0) {
                                                                            self.rightBoardLabel.textColor = [NSColor greenColor];
                                                                            self.rightBoardSubLabel.textColor = [NSColor greenColor];
                                                                        } else {
                                                                            self.rightBoardLabel.textColor = [NSColor labelColor];
                                                                            self.rightBoardSubLabel.textColor = [NSColor labelColor];
                                                                        }
                                                                        
                                                                        if (self.needToReshowBoard) {
                                                                            self.needToReshowBoard = NO;
                                                                            [self reshowBoardWithAnimation];
                                                                        }
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
        [self busyWithQuery:NO];

        [self parseData:data];
        [self.graphView draw];

        // if stock market is not yet queried back at this time, set the board status to undefined, waiting new stock market data updates it to normal.
        if (self.needToReshowBoard) {
            self.leftBoardLabel.stringValue = @"?.?";
            self.leftBoardSubLabel.stringValue = @"";
            self.rightBoardLabel.stringValue = @"?.?";
            self.rightBoardSubLabel.stringValue = @"";
        }
    });
}

- (void)reshowBoardWithAnimation
{
    self.leftBoardConstraint.constant = -self.leftBoard.frame.size.height;
    self.rightBoardConstraint.constant = -self.rightBoard.frame.size.height;

//    [NSAnimationContext beginGrouping];
//    [[NSAnimationContext currentContext] setDuration:0.5]; // default 0.25
//    self.leftBoardConstraint.animator.constant = -self.leftBoard.frame.size.height/2;
//    self.rightBoardConstraint.animator.constant = -self.rightBoard.frame.size.height/2;
//    [NSAnimationContext endGrouping];

    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    animation.toValue = @(-self.rightBoard.frame.size.height/2);
    animation.springBounciness = 16;
    animation.springSpeed = 8;
    animation.dynamicsFriction = 10;
    animation.dynamicsMass = 1;
    animation.dynamicsTension = 300;
    [self.leftBoardConstraint pop_addAnimation:animation forKey:@"leftSpring"];
    [self.rightBoardConstraint pop_addAnimation:animation forKey:@"rightSpring"];
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

#pragma mark - UI action

- (IBAction)btnManuallyRefreshDidClick:(id)sender {
    self.needToReshowBoard = YES;
    [self stopStockRefresher];

    NSLog(@"{input: \"%@\", type: %@}", self.labelStockCode.stringValue, self.popupGraphType.selectedItem.title);

    NSString *inputStockCode = [self.labelStockCode.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.inputStockCode = (inputStockCode.length == 0) ? kSDStockDaPanFullCode : inputStockCode;

    self.queryTaskType = (self.popupGraphType.indexOfSelectedItem == 0) ? TaskTypeRealtime : TaskTypeHistory;

    if ([self.inputStockCode isEqualToString:kSDStockDaPanFullCode]) {
        self.stockInfo = [[SDStockInfo alloc] initDaPan];

        self.forbiddenToRefresh = NO;
        [self startStockRefresher];

    } else {

        [self busyWithQuery:YES];

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
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 [self busyWithQuery:NO];

                                                                 self.forbiddenToRefresh = YES;
                                                                 [self showErrorMessage:@"Failed to query stock info. Invalid stock code."];
                                                             });
                                                         }];
    }
}

- (void)busyWithQuery:(BOOL)busy
{
    if (busy) {
        self.btnManuallyRefresh.image = nil;
        [self.progressForQuery startAnimation:self];

    } else {
        self.btnManuallyRefresh.image = [NSImage imageNamed:NSImageNameRevealFreestandingTemplate];
        [self.progressForQuery stopAnimation:self];
    }
}

- (void)showErrorMessage:(NSString *)errorMessage
{
    NSLog(@"%@", errorMessage);

    self.btnErrorMessage.title = [@" " stringByAppendingString:errorMessage];
    self.errorBarConstraint.animator.constant = 0;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kErrorBarDurationTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.errorBarConstraint.animator.constant = -self.errorBar.frame.size.height - 2;
    });
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
