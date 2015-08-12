//
//  TodayViewController.m
//  ExtensionTodayList
//
//  Created by GoKu on 8/11/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "TodayViewController.h"
#import "ListRowViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "SDCommonFetcher.h"

static NSUInteger const kDataRefreshInterval  = 5;

@interface TodayViewController () <NCWidgetProviding, NCWidgetListViewDelegate, NCWidgetSearchViewDelegate>

@property (strong) IBOutlet NCWidgetListViewController *listViewController;
@property (strong) NCWidgetSearchViewController *searchController;

@property (nonatomic, strong) NSTimer *refreshDataTaskTimer;
@property (nonatomic, assign) BOOL forbiddenToRefresh;

@end


@implementation TodayViewController

#pragma mark - NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up the widget list view controller.
    // The contents property should contain an object for each row in the list.
    self.listViewController.hasDividerLines = NO;
    self.listViewController.contents = [NSArray array]; // of SDStockMarket
}

- (void)dismissViewController:(NSViewController *)viewController {
    [super dismissViewController:viewController];

    // The search controller has been dismissed and is no longer needed.
    if (viewController == self.searchController) {
        self.searchController = nil;
    }
}

- (void)manuallyUpdateWidget
{
    [self stopStockRefresher];
    [self startStockRefresher];
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
    // query stock market
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SDCommonFetcher sharedSDCommonFetcher] fetchStockMarketWithStockInfo:nil
                                                                successHandler:^(SDStockMarket *stockMarket) {
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                    });
                                                                }
                                                                failureHandler:^(NSError *error) {
                                                                }];
    });
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    // Refresh the widget's contents in preparation for a snapshot.
    // Call the completion handler block after the widget's contents have been
    // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
    // or NCUpdateResultNewData to indicate that there is new data since the
    // last invocation of this method.

//    [self manuallyUpdateWidget];

    completionHandler(NCUpdateResultNoData);
}

- (NSEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(NSEdgeInsets)defaultMarginInset {
    // Override the left margin so that the list view is flush with the edge.
    defaultMarginInset.left = 0;
    defaultMarginInset.right = 0;
    return defaultMarginInset;
}

- (BOOL)widgetAllowsEditing {
    // Return YES to indicate that the widget supports editing of content and
    // that the list view should be allowed to enter an edit mode.
    return YES;
}

- (void)widgetDidBeginEditing {
    // The user has clicked the edit button.
    // Put the list view into editing mode.

    [self stopStockRefresher];

    self.listViewController.editing = YES;
}

- (void)widgetDidEndEditing {
    // The user has clicked the Done button, begun editing another widget,
    // or the Notification Center has been closed.
    // Take the list view out of editing mode.

//    [self manuallyUpdateWidget];

    self.listViewController.editing = NO;
}

#pragma mark - NCWidgetListViewDelegate

- (NSViewController *)widgetList:(NCWidgetListViewController *)list viewControllerForRow:(NSUInteger)row {
    // Return a new view controller subclass for displaying an item of widget
    // content. The NCWidgetListViewController will set the representedObject
    // of this view controller to one of the objects in its contents array.

    ListRowViewController *viewController = [[ListRowViewController alloc] init];

    return viewController;
}

- (void)widgetListPerformAddAction:(NCWidgetListViewController *)list {
    // The user has clicked the add button in the list view.
    // Display a search controller for adding new content to the widget.
    self.searchController = [[NCWidgetSearchViewController alloc] init];
    self.searchController.delegate = self;

    // Present the search view controller with an animation.
    // Implement dismissViewController to observe when the view controller
    // has been dismissed and is no longer needed.
    [self presentViewControllerInWidget:self.searchController];
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldReorderRow:(NSUInteger)row {
    // Return YES to allow the item to be reordered in the list by the user.
    return YES;
}

- (void)widgetList:(NCWidgetListViewController *)list didReorderRow:(NSUInteger)row toRow:(NSUInteger)newIndex {
    // The user has reordered an item in the list.
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldRemoveRow:(NSUInteger)row {
    // Return YES to allow the item to be removed from the list by the user.
    return YES;
}

- (void)widgetList:(NCWidgetListViewController *)list didRemoveRow:(NSUInteger)row {
    // The user has removed an item from the list.
}

#pragma mark - NCWidgetSearchViewDelegate

- (void)widgetSearch:(NCWidgetSearchViewController *)searchController searchForTerm:(NSString *)searchTerm maxResults:(NSUInteger)max {
    // The user has entered a search term. Set the controller's searchResults property to the matching items.

    searchController.searchResultsPlaceholderString = @"Please input stock code or pinyin abbr.";
    searchController.searchResultKeyPath = @"description"; // @"stockShortDisplayInfo" is also OK

    [[SDCommonFetcher sharedSDCommonFetcher] fetchStockInfoWithCode:searchTerm
                                                     successHandler:^(SDStockInfo *stockInfo) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             searchController.searchResults = @[stockInfo];
                                                         });
                                                     }
                                                     failureHandler:^(NSError *error) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             searchController.searchResults = nil;
                                                         });
                                                     }];
}

- (void)widgetSearchTermCleared:(NCWidgetSearchViewController *)searchController {
    // The user has cleared the search field. Remove the search results.
    searchController.searchResults = nil;
}

- (void)widgetSearch:(NCWidgetSearchViewController *)searchController resultSelected:(id)object {
    // The user has selected a search result from the list.

    SDStockInfo *selectedResult = (SDStockInfo *)object;
    SDStockMarket *stockMarket = [[SDStockMarket alloc] initWithStockInfo:selectedResult];
    self.listViewController.contents = [self.listViewController.contents arrayByAddingObject:stockMarket];
}

@end
