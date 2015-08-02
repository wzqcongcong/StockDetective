//
//  SDCommonFetcher.m
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

@import AFNetworking;
#import "SDCommonFetcher.h"

static NSString * const kFetchStockInfoFormatURL = @"http://suggest.eastmoney.com/suggest/default.aspx?name=sData&input=%@&type=1,2,3";

@interface SDCommonFetcher ()

@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfig;
@property (nonatomic, strong) AFURLSessionManager *sessionManager;

@end

@implementation SDCommonFetcher

+ (SDCommonFetcher *)sharedSDCommonFetcher
{
    static SDCommonFetcher *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDCommonFetcher alloc] init];

        sharedInstance.sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sharedInstance.sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;

        sharedInstance.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sharedInstance.sessionConfig];
        sharedInstance.sessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        sharedInstance.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    });
    return sharedInstance;
}

- (void)fetchStockInfoWithCode:(NSString *)code
             completionHandler:(void (^)(SDStockInfo *stockInfo))completionHandler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kFetchStockInfoFormatURL, code]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:request
                                                            completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                if (error) {
                                                                    NSLog(@"Error: %@", error);
                                                                } else {
                                                                    NSString *string = [[NSString alloc] initWithData:(NSData *)responseObject encoding:kNSGB18030StringEncoding];
                                                                    NSRange range1 = [string rangeOfString:@"\""];
                                                                    NSRange range2 = [string rangeOfString:@"\"" options:NSBackwardsSearch];

                                                                    if (range1.location != NSNotFound &&
                                                                        range2.location != NSNotFound &&
                                                                        range2.location - range1.location > 1) {

                                                                        NSString *content = [string substringWithRange:NSMakeRange(range1.location+1, range2.location-range1.location-1)];
                                                                        NSArray *array = [content componentsSeparatedByString:@","];

                                                                        if (array.count == 7) {
                                                                            SDStockInfo *stockInfo = [[SDStockInfo alloc] init];
                                                                            stockInfo.stockCode = code;
                                                                            stockInfo.stockName = array[4];
                                                                            stockInfo.stockAbbr = array[3];
                                                                            stockInfo.stockType = [array[5] isEqualToString:@"1"] ? kStockTypeSH : kStockTypeSZ;

                                                                            NSLog(@"%@", stockInfo);

                                                                            completionHandler(stockInfo);
                                                                        }
                                                                    }
                                                                }
                                                            }];
    [dataTask resume];
}

@end
