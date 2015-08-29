//
//  AppDelegate.m
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDAppDelegate.h"
#import "SDMainWindowController.h"
#import "LogFormatter.h"

@interface SDAppDelegate ()

@property (nonatomic, strong) SDMainWindowController *mainWindowController;

@end

@implementation SDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    [LogFormatter setupLog];

    self.mainWindowController = [[SDMainWindowController alloc] init];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];

    [self.mainWindowController startStockRefresher];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (!self.mainWindowController.window.isVisible &&
        !self.mainWindowController.window.isMiniaturized) { // window is closed

        [self.mainWindowController showWindow:self];
        [self.mainWindowController.window makeKeyAndOrderFront:self];

        [self.mainWindowController startStockRefresher];
    }

    return YES;
}

@end
