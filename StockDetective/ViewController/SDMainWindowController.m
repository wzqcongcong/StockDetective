//
//  SDMainWindowController.m
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import Yuba;
#import "SDMainWindowController.h"
#import "SDGraphMarkerViewController.h"

@interface SDMainWindowController ()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *legend;
@property (nonatomic, strong) NSArray *series;
@property (nonatomic, strong) NSArray *values;

@property (weak) IBOutlet YBGraphView *graphView;

@end

@implementation SDMainWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"SDMainWindowController"];
    if (self) {

    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;

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
    self.title = array[0];
    
    self.graphView.info = self.title;
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
    return [NSString stringWithFormat:@"%ld M", [[(NSArray *)(self.values[graphIndex]) objectAtIndex:elementIndex] integerValue]];
}

- (NSView *)graphView:(YBGraphView *)graph markerViewForGraph:(NSInteger)graphIndex forElement:(NSInteger)elementIndex {
    SDGraphMarkerViewController *graphMarkerViewController = [[SDGraphMarkerViewController alloc] init];
    graphMarkerViewController.view.hidden = NO;
    graphMarkerViewController.label.attributedStringValue = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld M", [[(NSArray *)(self.values[graphIndex]) objectAtIndex:elementIndex] integerValue]]
                                                                                            attributes:@{NSForegroundColorAttributeName: [YBGraphView colorByIndex:graphIndex]}];
    return graphMarkerViewController.view;
}

@end