//
//  SDUtilities.m
//  StockDetective
//
//  Created by GoKu on 8/15/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDUtilities.h"

static NSString * const kSharedStockDataCacheName = @"SharedStockDataCache";
static NSString * const kCacheTypeRefreshData = @"CacheTypeRefreshData";
static NSString * const kCacheTypeStockMarket = @"CacheTypeStockMarket";

@interface SDUtilities ()

@end

@implementation SDUtilities

+ (BOOL)isStockMarketOnBusiness
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];

    if ([calendar isDateInWeekend:today]) {
        return NO;

    } else {
        NSDate *today9 = [calendar dateBySettingHour:9
                                              minute:0
                                              second:0
                                              ofDate:today
                                             options:NSCalendarMatchStrictly];
        NSDate *today15 = [calendar dateBySettingHour:15
                                               minute:0
                                               second:0
                                               ofDate:today
                                              options:NSCalendarMatchStrictly];
        if (([today compare:today9] == NSOrderedAscending) || ([today compare:today15] == NSOrderedDescending)) {
            return NO;

        } else {
            return YES;
        }
    }
}

#pragma mark - stock data cache

+ (NSCache *)sharedStockDataCache
{
    static NSCache *sharedCache = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedCache = [[NSCache alloc] init];
        sharedCache.name = [NSString stringWithFormat:@"%@.%@", [NSBundle mainBundle].bundleIdentifier, kSharedStockDataCacheName];
    });
    return sharedCache;
}


+ (NSData *)loadCachedRefreshDataForURL:(NSString *)url
{
    return [[SDUtilities sharedStockDataCache] objectForKey:[kCacheTypeRefreshData stringByAppendingString:url]];
}

+ (void)cacheRefreshData:(NSData *)data forURL:(NSString *)url
{
    if (data) {
        [[SDUtilities sharedStockDataCache] setObject:data
                                               forKey:[kCacheTypeRefreshData stringByAppendingString:url]];
    } else {
        [[SDUtilities sharedStockDataCache] removeObjectForKey:[kCacheTypeRefreshData stringByAppendingString:url]];
    }
}

+ (SDStockMarket *)loadCachedStockMarketForFullStockCode:(NSString *)fullStockCode
{
    return [[SDUtilities sharedStockDataCache] objectForKey:[kCacheTypeStockMarket stringByAppendingString:fullStockCode]];
}

+ (void)cacheStockMarket:(SDStockMarket *)stockMarket forFullStockCode:(NSString *)fullStockCode
{
    if (stockMarket) {
        [[SDUtilities sharedStockDataCache] setObject:stockMarket
                                               forKey:[kCacheTypeStockMarket stringByAppendingString:fullStockCode]];
    } else {
        [[SDUtilities sharedStockDataCache] removeObjectForKey:[kCacheTypeStockMarket stringByAppendingString:fullStockCode]];
    }
}

@end
