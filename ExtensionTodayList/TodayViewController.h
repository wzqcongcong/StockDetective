//
//  TodayViewController.h
//  ExtensionTodayList
//
//  Created by GoKu on 8/11/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDRefreshDataTask.h"
#import "ListRowViewController.h"

@interface TodayViewController : NSViewController <SDRefreshDataTaskManagerProtocol, ExtensionTodayListRowViewControllerDelegate>

@property (atomic, strong) NSDate *lastRefreshedByDataTaskStartDate;

@end
