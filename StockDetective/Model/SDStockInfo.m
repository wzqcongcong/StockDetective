//
//  SDStockInfo.m
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDStockInfo.h"

NSString * const kSDStockTypeSH         = @"SH";
NSString * const kSDStockTypeSZ         = @"SZ";

NSString * const kSDStockHuZhiName      = @"上证指数";
NSString * const kSDStockHuZhiCode      = @"000001";
NSString * const kSDStockHuZhiAbbr      = @"SZZS";
NSString * const kSDStockHuZhiType      = @"SH";
NSString * const kSDStockHuZhiFullCode  = @"SH000001";

NSString * const kSDStockShenZhiName      = @"深证成指";
NSString * const kSDStockShenZhiCode      = @"399001";
NSString * const kSDStockShenZhiAbbr      = @"SZCZ";
NSString * const kSDStockShenZhiType      = @"SZ";
NSString * const kSDStockShenZhiFullCode  = @"SZ399001";

@implementation SDStockInfo

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (instancetype)initHuZhi
{
    self = [super init];
    if (self) {
        _stockCode = kSDStockHuZhiCode;
        _stockName = kSDStockHuZhiName;
        _stockAbbr = kSDStockHuZhiAbbr;
        _stockType = kSDStockHuZhiType;
    }
    return self;
}

- (instancetype)initShenZhi
{
    self = [super init];
    if (self) {
        _stockCode = kSDStockShenZhiCode;
        _stockName = kSDStockShenZhiName;
        _stockAbbr = kSDStockShenZhiAbbr;
        _stockType = kSDStockShenZhiType;
    }
    return self;
}

- (BOOL)isValidStock
{
    return (self.stockCode && self.stockName && self.stockAbbr && self.stockType);
}

- (NSString *)fullStockCode
{
    return [self.stockType stringByAppendingString:self.stockCode];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@) [%@]", self.stockName, self.stockAbbr, [self fullStockCode]];
}

- (NSString *)stockShortDisplayInfo
{
    return [NSString stringWithFormat:@"%@ [%@]", self.stockName, [self fullStockCode]];
}

- (NSString *)stockShortDisplayInfoV2
{
    return [NSString stringWithFormat:@"[%@] %@", [self fullStockCode], self.stockName];
}

@end
