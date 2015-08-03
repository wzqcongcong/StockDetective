//
//  SDStockInfo.m
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDStockInfo.h"

NSString * const kSDStockCodeDaPan  = @"大盘";

NSString * const kSDStockTypeSH     = @"SH";
NSString * const kSDStockTypeSZ     = @"SZ";

@implementation SDStockInfo

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@) [%@%@]", self.stockName, self.stockAbbr, self.stockType, self.stockCode];
}

- (NSString *)stockShortDisplayInfo
{
    return [NSString stringWithFormat:@"%@ [%@%@]", self.stockName, self.stockType, self.stockCode];
}

@end
