//
//  SDCommonFetcher.h
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDStockInfo.h"
#import "SDStockMarket.h"
#import "SDUserInfo.h"

#define kNSGB18030StringEncoding    (CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000))

@interface SDCommonFetcher : NSObject

+ (SDCommonFetcher *)sharedSDCommonFetcher; // NS_DESIGNATED_INITIALIZER

- (void)fetchStockInfoWithCode:(NSString *)code
                successHandler:(void (^)(SDStockInfo *stockInfo))successHandler
                failureHandler:(void (^)(NSError *error))failureHandler;

- (void)fetchStockMarketWithStockInfo:(SDStockInfo *)stockInfo
                       successHandler:(void (^)(SDStockMarket *stockMarket))successHandler
                       failureHandler:(void (^)(NSError *error))failureHandler;

@end
