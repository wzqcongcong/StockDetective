//
//  ListRowViewController.m
//  ExtensionTodayList
//
//  Created by GoKu on 8/11/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import Yuba;
#import "ListRowViewController.h"
#import "SDStockMarket.h"

@interface ListRowViewController ()

@property (weak) id<ExtensionTodayListRowViewControllerDelegate> owner;

@property (weak) IBOutlet NSLayoutConstraint *constraintGrahpView;
@property (weak) IBOutlet YBGraphView *graphView;

@property (nonatomic, strong) NSString *dataUnit;
@property (nonatomic, strong) NSArray *legend;
@property (nonatomic, strong) NSArray *series;
@property (nonatomic, strong) NSArray *values;

@end

@implementation ListRowViewController

- (NSString *)nibName {
    return @"ListRowViewController";
}

- (instancetype)initWithOwner:(id<ExtensionTodayListRowViewControllerDelegate>)owner
{
    self = [super init];
    if (self) {
        _owner = owner;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    // Insert code here to customize the view
    self.constraintGrahpView.constant = -self.graphView.frame.size.height;

    [self setupGraphConfig];
}

- (void)closeDetailView
{
    if (self.constraintGrahpView.constant == 10) {
        self.constraintGrahpView.animator.constant = -self.graphView.frame.size.height;
    }
}

#pragma mark - ui action

- (IBAction)didClickTitleBar:(id)sender {
    if (self.constraintGrahpView.constant == 10) {
        self.constraintGrahpView.animator.constant = -self.graphView.frame.size.height;
        [self.owner didClickRowVC:self toOpen:NO];

    } else {
        self.constraintGrahpView.animator.constant = 10;
        [self.owner didClickRowVC:self toOpen:YES];
    }
}

#pragma mark - draw graph

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

    self.graphView.info = [NSString stringWithFormat:@"%@ (%@)", [(SDStockMarket *)(self.representedObject) stockShortDisplayInfo], array[0]];
}

- (void)updateViewWithData:(NSData *)data
{
    [self parseData:data];
    [self.graphView draw];
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

@end
