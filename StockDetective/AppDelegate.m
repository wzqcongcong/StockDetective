//
//  AppDelegate.m
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "AppDelegate.h"
#import "SDMainWindowController.h"


@interface AppDelegate ()

@property (nonatomic, strong) NSTimer *refreshDataTaskTimer;
@property (nonatomic, strong) NSString *stockCode;

@property (nonatomic, strong) SDMainWindowController *mainWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    self.mainWindowController = [[SDMainWindowController alloc] init];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];

    self.stockCode = @"大盘"; // 指定具体股票时这里需要修改成相应的股票代码，例如，中国平安：000001

    self.refreshDataTaskTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                                 target:self
                                                               selector:@selector(doRefreshDataTask)
                                                               userInfo:nil
                                                                repeats:YES];
    [self.refreshDataTaskTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application

    [self.refreshDataTaskTimer invalidate];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];

    return YES;
}

- (void)doRefreshDataTask
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SDRefreshDataTask *refreshDataTask = [[SDRefreshDataTask alloc] init];
        refreshDataTask.taskManager = self;
        [refreshDataTask refreshDataTask:TaskTypeRealtime
                               stockCode:self.stockCode
                       completionHandler:^(NSData *data) {
                           [self.mainWindowController updateViewWithStockCode:self.stockCode data:data];
                       }];
    });
}

@end
