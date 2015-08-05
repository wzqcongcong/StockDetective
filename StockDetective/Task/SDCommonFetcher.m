//
//  SDCommonFetcher.m
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "AFNetworking.h"
#import "SDCommonFetcher.h"

static NSString * const kFetchStockInfoFormatURL = @"http://suggest.eastmoney.com/suggest/default.aspx?name=sData&input=%@&type=1,2,3";
static NSString * const kFetchStockMarketFormatURL = @"http://xueqiu.com/v4/stock/quote.json?code=%@"; // by full code, like SH000001.

static NSString * const kXueQiuLoginURL = @"http://xueqiu.com/user/login";
static NSString * const kXueQiuLoginUsername = @"wzqcongcong@sina.com";
static NSString * const kXueQiuLoginPassword = @"wzq424327";

@interface SDCommonFetcher ()

@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfig;

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
        sharedInstance.sessionConfig.HTTPCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    });
    return sharedInstance;
}

- (void)fetchStockInfoWithCode:(NSString *)code
                successHandler:(void (^)(SDStockInfo *stockInfo))successHandler
                failureHandler:(void (^)(NSError *error))failureHandler;
{
    AFURLSessionManager *sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:self.sessionConfig];
    sessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer]; // non json
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kFetchStockInfoFormatURL, code]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSURLSessionDataTask *dataTask = [sessionManager dataTaskWithRequest:request
                                                       completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                           if (error) {
                                                               if (failureHandler) {
                                                                   failureHandler(error);
                                                               }

                                                           } else {
                                                               NSString *string = [[NSString alloc] initWithData:(NSData *)responseObject encoding:kNSGB18030StringEncoding];
                                                               NSRange range1 = [string rangeOfString:@"\""];
                                                               NSRange range2 = [string rangeOfString:@"\"" options:NSBackwardsSearch];

                                                               if (range1.location != NSNotFound &&
                                                                   range2.location != NSNotFound &&
                                                                   range2.location - range1.location > 1) {

                                                                   NSString *content = [string substringWithRange:NSMakeRange(range1.location+1, range2.location-range1.location-1)];
                                                                   NSArray *arrayAll = [content componentsSeparatedByString:@";"];

                                                                   if (arrayAll.count > 0) {
                                                                       NSArray *array = [(NSString *)(arrayAll.firstObject) componentsSeparatedByString:@","];

                                                                       SDStockInfo *stockInfo = [[SDStockInfo alloc] init];
                                                                       stockInfo.stockCode = array[1];
                                                                       stockInfo.stockName = array[4];
                                                                       stockInfo.stockAbbr = array[3];
                                                                       stockInfo.stockType = [array[5] isEqualToString:@"1"] ? kSDStockTypeSH : kSDStockTypeSZ;

                                                                       NSLog(@"%@", stockInfo);

                                                                       if (successHandler) {
                                                                           successHandler(stockInfo);
                                                                       }

                                                                   } else {
                                                                       if (failureHandler) {
                                                                           failureHandler(nil);
                                                                       }
                                                                   }

                                                               } else {
                                                                   if (failureHandler) {
                                                                       failureHandler(nil);
                                                                   }
                                                               }
                                                           }
                                                       }];
    [dataTask resume];
}

- (void)fetchStockMarketWithStockInfo:(SDStockInfo *)stockInfo
                       successHandler:(void (^)(SDStockMarket *stockMarket))successHandler
                       failureHandler:(void (^)(NSError *error))failureHandler
{
    if ([self validXueQiuCookie]) {
        [self fetchStockMarketByXueQiuWithStockInfo:stockInfo
                                     successHandler:^(SDStockMarket *stockMarket) {
                                         successHandler(stockMarket);
                                     }
                                     failureHandler:^(NSError *error) {
                                         NSLog(@"Failed to fetch stock market from XueQiu: %@", error);
                                         if (failureHandler) {
                                             failureHandler(error);
                                         }
                                     }];

    } else {
        SDUserInfo *userInfo = [[SDUserInfo alloc] init];
        userInfo.username = kXueQiuLoginUsername;
        userInfo.password = kXueQiuLoginPassword;

        [self loginXueQiuWithUserInfo:userInfo
                       successHandler:^() {
                           [self fetchStockMarketByXueQiuWithStockInfo:stockInfo
                                                        successHandler:^(SDStockMarket *stockMarket) {
                                                            successHandler(stockMarket);
                                                        }
                                                        failureHandler:^(NSError *error) {
                                                            NSLog(@"Failed to fetch stock market from XueQiu: %@", error);
                                                            if (failureHandler) {
                                                                failureHandler(error);
                                                            }
                                                        }];
                       }
                       failureHandler:^(NSError *error) {
                           NSLog(@"Failed to login XueQiu: %@", error);
                           if (failureHandler) {
                               failureHandler(error);
                           }
                       }];
    }
}

#pragma mark - XueQiu

- (void)loginXueQiuWithUserInfo:(SDUserInfo *)userInfo
                 successHandler:(void (^)())successHandler
                 failureHandler:(void (^)(NSError *error))failureHandler
{
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:self.sessionConfig];
    sessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:userInfo.username password:userInfo.password];
    sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer]; // non json

    NSURL *domainURL = [NSURL URLWithString:[NSURL URLWithString:kXueQiuLoginURL].host];
    [sessionManager POST:kXueQiuLoginURL
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     NSDictionary *header = [(NSHTTPURLResponse *)(task.response) allHeaderFields];
                     NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:header
                                                                               forURL:domainURL];
                     [self.sessionConfig.HTTPCookieStorage setCookies:cookies
                                                               forURL:domainURL
                                                      mainDocumentURL:domainURL];

                     if (successHandler) {
                         successHandler();
                     }
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error) {
                     if (failureHandler) {
                         failureHandler(error);
                     }
                 }];
}

- (void)fetchStockMarketByXueQiuWithStockInfo:(SDStockInfo *)stockInfo
                               successHandler:(void (^)(SDStockMarket *stockMarket))successHandler
                               failureHandler:(void (^)(NSError *error))failureHandler
{
    AFURLSessionManager *sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:self.sessionConfig];
    sessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    // sessionManager.responseSerializer: default json

    NSString *fullCode = stockInfo ? [stockInfo.stockType stringByAppendingString:stockInfo.stockCode] : kSDStockFullCodeDaPan;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kFetchStockMarketFormatURL, fullCode]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.mainDocumentURL = [NSURL URLWithString:url.host];

    NSURLSessionDataTask *dataTask = [sessionManager dataTaskWithRequest:request
                                                       completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                           if (error) {
                                                               if (failureHandler) {
                                                                   failureHandler(error);
                                                               }

                                                           } else {
                                                               NSDictionary *responseDic = (NSDictionary *)responseObject;
                                                               if (responseDic && [[responseDic allKeys] containsObject:fullCode]) {
                                                                   NSDictionary *stockDic = responseDic[fullCode];
                                                                   SDStockMarket *stockMarket = stockInfo ? [[SDStockMarket alloc] initWithStockInfo:stockInfo] : [[SDStockMarket alloc] init];
                                                                   stockMarket.currentPrice = stockDic[@"current"];

                                                                   if (successHandler) {
                                                                       successHandler(stockMarket);
                                                                   }

                                                               } else {
                                                                   if (failureHandler) {
                                                                       failureHandler(nil);
                                                                   }
                                                               }
                                                           }
                                                       }];
    [dataTask resume];
}

- (BOOL)validXueQiuCookie
{
    return NO;
}

@end
