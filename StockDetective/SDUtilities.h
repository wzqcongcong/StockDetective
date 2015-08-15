//
//  SDUtilities.h
//  StockDetective
//
//  Created by GoKu on 8/15/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDStockMarket.h"

@interface SDUtilities : NSObject

+ (BOOL)isStockMarketOnBusiness;

+ (NSData *)loadCachedRefreshDataForURL:(NSString *)url;
+ (void)cacheRefreshData:(NSData *)data forURL:(NSString *)url;

+ (SDStockMarket *)loadCachedStockMarketForFullStockCode:(NSString *)fullStockCode;
+ (void)cacheStockMarket:(SDStockMarket *)stockMarket forFullStockCode:(NSString *)fullStockCode;

@end
