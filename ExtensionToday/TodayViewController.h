//
//  TodayViewController.h
//  ExtensionToday
//
//  Created by GoKu on 8/10/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDRefreshDataTask.h"

@interface TodayViewController : NSViewController <SDRefreshDataTaskManagerProtocol>

@property (atomic, strong) NSDate *lastRefreshedByDataTaskStartDate;

@end
