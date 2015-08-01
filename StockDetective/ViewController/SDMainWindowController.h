//
//  SDMainWindowController.h
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDRefreshDataTask.h"

@interface SDMainWindowController : NSWindowController <NSWindowDelegate, SDRefreshDataTaskManagerProtocol>

- (void)startStockRefresher;
- (void)stopStockRefresher;

@property (atomic, strong) NSDate *lastRefreshedByDataTaskStartDate;

@end
