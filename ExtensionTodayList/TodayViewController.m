//
//  TodayViewController.m
//  ExtensionTodayList
//
//  Created by GoKu on 8/11/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "SDCommonFetcher.h"

static NSUInteger const kDataRefreshInterval  = 5;

static NSString * const kExtensionTodayListSavedStocks = @"ExtensionTodayListSavedStocks";

@interface TodayViewController () <NCWidgetProviding, NCWidgetListViewDelegate, NCWidgetSearchViewDelegate>

@property (strong) IBOutlet NCWidgetListViewController *listViewController;
@property (strong) NCWidgetSearchViewController *searchController;

@property (nonatomic, strong) NSTimer *refreshDataTaskTimer;
@property (nonatomic, assign) TaskType queryTaskType;
@property (nonatomic, weak) ListRowViewController *rowVCShowingDetail;

@end


@implementation TodayViewController

#pragma mark - NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up the widget list view controller.
    // The contents property should contain an object for each row in the list.
    self.rowVCShowingDetail = nil;

    self.listViewController.hasDividerLines = NO;
    self.listViewController.contents = [NSArray array]; // of SDStockMarket

    self.queryTaskType = TaskTypeRealtime;
}

- (void)dismissViewController:(NSViewController *)viewController {
    [super dismissViewController:viewController];

    // The search controller has been dismissed and is no longer needed.
    if (viewController == self.searchController) {
        self.searchController = nil;
    }
}

- (void)startStockRefresher
{
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
    // query stock data for showing stock
    if (self.rowVCShowingDetail) {
        SDStockMarket *stockMarket = self.rowVCShowingDetail.representedObject;

        NSString *searchCode = stockMarket.stockCode;
        if ([[stockMarket.stockType stringByAppendingString:stockMarket.stockCode] isEqualToString:kSDStockDaPanFullCode]) {
            searchCode = kSDStockDaPanFullCode;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            SDRefreshDataTask *refreshDataTask = [[SDRefreshDataTask alloc] init];
            refreshDataTask.taskManager = self;
            [refreshDataTask refreshDataTask:self.queryTaskType
                                   stockCode:searchCode
                              successHandler:^(NSData *data) {
                                  SDStockMarket *showingStockMarket = self.rowVCShowingDetail.representedObject;

                                  // check if returned data is of current showing stock
                                  if ([searchCode isEqualToString:showingStockMarket.stockCode] ||
                                      [searchCode isEqualToString:[showingStockMarket.stockType stringByAppendingString:showingStockMarket.stockCode]]) {
                                      [self updateViewWithData:data];
                                  }
                              }
                              failureHandler:^(NSError *error) {
                              }];
        });
    }
    
    // query stock market
    for (SDStockMarket *theStockMarket in self.listViewController.contents) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[SDCommonFetcher sharedSDCommonFetcher] fetchStockMarketWithStockInfo:theStockMarket
                                                                    successHandler:^(SDStockMarket *stockMarket) {
//                                                                        NSLog(@"%@", [stockMarket currentPriceDescription]);

                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            theStockMarket.currentPrice = stockMarket.currentPrice;
                                                                            theStockMarket.changeValue = stockMarket.changeValue;
                                                                            theStockMarket.changePercentage = stockMarket.changePercentage;
                                                                        });
                                                                    }
                                                                    failureHandler:^(NSError *error) {
                                                                    }];
        });
    }
}

- (void)updateViewWithData:(NSData *)data
{
    if (data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rowVCShowingDetail updateViewWithData:data];
        });
    }
}

#pragma mark - ExtensionTodayListRowViewControllerDelegate

- (void)didClickRowVC:(ListRowViewController *)listRowVC toOpen:(BOOL)open
{
    if (!self.listViewController.editing) {
        if (open) {
            [self stopStockRefresher];

            [self.rowVCShowingDetail closeDetailView];

            self.rowVCShowingDetail = listRowVC;

            [self startStockRefresher];

        } else {
            self.rowVCShowingDetail = nil;
        }
    }
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    // Refresh the widget's contents in preparation for a snapshot.
    // Call the completion handler block after the widget's contents have been
    // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
    // or NCUpdateResultNewData to indicate that there is new data since the
    // last invocation of this method.

    [self stopStockRefresher];

    self.rowVCShowingDetail = nil;

    NSArray *savedContent = [self readSavedContents];
    self.listViewController.contents = savedContent.count > 0 ? savedContent : @[[[SDStockMarket alloc] initDaPan]];

    [self startStockRefresher];

    // after 2s, show the 1st stock if needed
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.rowVCShowingDetail) {
            ListRowViewController *rowVC = (ListRowViewController *)[self.listViewController viewControllerAtRow:0 makeIfNecessary:YES];
            [rowVC didClickTitleBar:nil];
        }
    });

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

    self.listViewController.editing = NO;

    [self saveContents];

    [self startStockRefresher];
}

#pragma mark - NCWidgetListViewDelegate

- (NSViewController *)widgetList:(NCWidgetListViewController *)list viewControllerForRow:(NSUInteger)row {
    // Return a new view controller subclass for displaying an item of widget
    // content. The NCWidgetListViewController will set the representedObject
    // of this view controller to one of the objects in its contents array.

    ListRowViewController *viewController = [[ListRowViewController alloc] initWithOwner:self];

    return viewController;
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldReorderRow:(NSUInteger)row {
    // Return YES to allow the item to be reordered in the list by the user.
    return YES;
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldRemoveRow:(NSUInteger)row {
    // Return YES to allow the item to be removed from the list by the user.
    return YES;
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

#pragma mark - NCWidgetSearchViewDelegate

- (void)widgetSearch:(NCWidgetSearchViewController *)searchController searchForTerm:(NSString *)searchTerm maxResults:(NSUInteger)max {
    // The user has entered a search term. Set the controller's searchResults property to the matching items.

    searchController.searchResultsPlaceholderString = @"Please input stock code or pinyin abbr.";
    searchController.searchResultKeyPath = @"description"; // @"stockShortDisplayInfo" is also OK

    NSString *trimmedSearchTerm = [searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmedSearchTerm.length == 0) {
        searchController.searchResults = @[[[SDStockInfo alloc] initDaPan]];

    } else {
        [[SDCommonFetcher sharedSDCommonFetcher] fetchStockInfoWithCode:trimmedSearchTerm
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
}

- (void)widgetSearchTermCleared:(NCWidgetSearchViewController *)searchController {
    // The user has cleared the search field. Remove the search results.
    searchController.searchResults = nil;
}

- (void)widgetSearch:(NCWidgetSearchViewController *)searchController resultSelected:(id)object {
    // The user has selected a search result from the list.

    SDStockInfo *selectedResult = (SDStockInfo *)object;
    SDStockMarket *selectedStockMarket = [[SDStockMarket alloc] initWithStockInfo:selectedResult];

    BOOL existed = NO;
    for (SDStockMarket *stockMarket in self.listViewController.contents) {
        if ([[stockMarket stockShortDisplayInfo] isEqualToString:[selectedStockMarket stockShortDisplayInfo]]) {
            existed = YES;
            break;
        }
    }

    // only add a new one
    if (!existed) {
        self.listViewController.contents = [self.listViewController.contents arrayByAddingObject:selectedStockMarket];
    }
}

#pragma mark - NSUserDefaults

- (NSArray *)readSavedContents
{
    NSArray *savedArray = [[NSUserDefaults standardUserDefaults] arrayForKey:kExtensionTodayListSavedStocks];

    NSMutableArray *savedContent = [NSMutableArray array];

    for (NSDictionary *stockDic in savedArray) {
        SDStockMarket *stockMarket = [[SDStockMarket alloc] init];
        stockMarket.stockCode = stockDic[@"code"];
        stockMarket.stockName = stockDic[@"name"];
        stockMarket.stockType = stockDic[@"type"];
        stockMarket.stockAbbr = stockDic[@"abbr"];
        [savedContent addObject:stockMarket];
    }

    return savedContent;
}

- (void)saveContents
{
    NSMutableArray *toSaveArray = [NSMutableArray array];

    for (SDStockMarket *stockMarket in self.listViewController.contents) {
        NSDictionary *stockDic = @{@"code": stockMarket.stockCode,
                                   @"name": stockMarket.stockName,
                                   @"type": stockMarket.stockType,
                                   @"abbr": stockMarket.stockAbbr};
        [toSaveArray addObject:stockDic];
    }

    [[NSUserDefaults standardUserDefaults] setObject:toSaveArray forKey:kExtensionTodayListSavedStocks];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
