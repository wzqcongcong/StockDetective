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

NSString * const kSDStockDaPanName      = @"上证指数";
NSString * const kSDStockDaPanCode      = @"000001";
NSString * const kSDStockDaPanAbbr      = @"SZZS";
NSString * const kSDStockDaPanType      = @"SH";

NSString * const kSDStockDaPanFullCode  = @"SH000001";

@implementation SDStockInfo

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (instancetype)initDaPan
{
    self = [super init];
    if (self) {
        _stockCode = kSDStockDaPanCode;
        _stockName = kSDStockDaPanName;
        _stockAbbr = kSDStockDaPanAbbr;
        _stockType = kSDStockDaPanType;
    }
    return self;
}

- (BOOL)isValidStock
{
    return (self.stockCode && self.stockName && self.stockAbbr && self.stockType);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@) [%@%@]", self.stockName, self.stockAbbr, self.stockType, self.stockCode];
}

- (NSString *)stockShortDisplayInfo
{
    return [NSString stringWithFormat:@"%@ [%@%@]", self.stockName, self.stockType, self.stockCode];
}

@end
