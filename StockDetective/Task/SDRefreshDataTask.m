//
//  SDRefreshDataTask.m
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import AFNetworking;
#import "SDRefreshDataTask.h"

static NSString * const kQueryDaPanRealtimeFormatURL = @"http://s1.dfcfw.com/allXML/index.xml";
static NSString * const kQueryDaPanHistoryFormatURL = @"http://s1.dfcfw.com/History/index.xml";

static NSString * const kQueryRealtimeFormatURL = @"http://s1.dfcfw.com/allXML/%@.xml";
static NSString * const kQueryHistoryFormatURL = @"http://data.eastmoney.com/zjlx/graph/his_%@.html";

@interface SDRefreshDataTask ()

@property (nonatomic, strong) NSDate *refreshDataTaskStartDate;

@end

@implementation SDRefreshDataTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _refreshDataTaskStartDate = [NSDate distantPast];
    }
    return self;
}

- (void)refreshDataTask:(TaskType)taskType
              stockCode:(NSString *)stockCode
      completionHandler:(void (^)(NSData *))completionHandler
{
    if (self.taskManager) {
        NSURL *url;

        switch (taskType) {
            case TaskTypeRealtime:
            {
                if ([stockCode integerValue] == 0) { // 大盘
                    url = [NSURL URLWithString:kQueryDaPanRealtimeFormatURL];
                } else {
                    url = [NSURL URLWithString:[NSString stringWithFormat:kQueryRealtimeFormatURL, stockCode]];
                }
                break;
            }
            case TaskTypeHistory:
            {
                if ([stockCode integerValue] == 0) { // 大盘
                    url = [NSURL URLWithString:kQueryDaPanHistoryFormatURL];
                } else {
                    url = [NSURL URLWithString:[NSString stringWithFormat:kQueryHistoryFormatURL, stockCode]];
                }
                break;
            }
            default:
                break;
        }

        self.refreshDataTaskStartDate = [NSDate date];

        [self fetchDataOfURL:url
           completionHandler:^(NSData *data) {
               // if manager has already refreshed by another newer task (by network factor), ignore this old task.
               if (!self.taskManager.lastRefreshedByDataTaskStartDate ||
                   ([self.taskManager.lastRefreshedByDataTaskStartDate compare:self.refreshDataTaskStartDate] == NSOrderedAscending)) {

                   self.taskManager.lastRefreshedByDataTaskStartDate = self.refreshDataTaskStartDate;
                   if (completionHandler) {
                       completionHandler(data);
                   }
                   NSLog(@"data refreshed");

               } else {
                   NSLog(@"ignore old task");
               }
           }];
    }
}

- (void)fetchDataOfURL:(NSURL *)url
     completionHandler:(void (^)(NSData *data))completionHandler
{
    if (!url) {
        return;
    }

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;

    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request
                                                completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                    if (error) {
                                                        NSLog(@"Error: %@", error);
                                                    } else {
                                                        completionHandler((NSData *)responseObject);
                                                    }
                                                }];
    [dataTask resume];
}

@end
