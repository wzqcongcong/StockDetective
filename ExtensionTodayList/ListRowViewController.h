//
//  ListRowViewController.h
//  ExtensionTodayList
//
//  Created by GoKu on 8/11/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ListRowViewController;

@protocol ExtensionTodayListRowViewControllerDelegate <NSObject>

- (void)didClickRowVC:(ListRowViewController *)listRowVC toOpen:(BOOL)open;

@end

@interface ListRowViewController : NSViewController

- (instancetype)initWithOwner:(id<ExtensionTodayListRowViewControllerDelegate>)owner; // NS_DESIGNATED_INITIALIZER

- (IBAction)didClickTitleBar:(id)sender;
- (void)closeDetailView;
- (void)updateViewWithData:(NSData *)data;

@end
