//
//  AppDelegate.h
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDRefreshDataTask.h"


@interface AppDelegate : NSObject <NSApplicationDelegate, SDRefreshDataTaskManagerProtocol>

@property (atomic, strong) NSDate *lastRefreshedByDataTaskStartDate;

@end

