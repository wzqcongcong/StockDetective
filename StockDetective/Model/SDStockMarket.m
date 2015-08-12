//
//  SDStockMarket.m
//  StockDetective
//
//  Created by GoKu on 8/4/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDStockMarket.h"

@implementation SDStockMarket

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (instancetype)initWithStockInfo:(SDStockInfo *)stockInfo
{
    self = [super init];
    if (self) {
        self.stockCode = stockInfo.stockCode;
        self.stockName = stockInfo.stockName;
        self.stockAbbr = stockInfo.stockAbbr;
        self.stockType = stockInfo.stockType;
    }
    return self;
}

- (NSString *)currentPriceDescription
{
    return [NSString stringWithFormat:@"%@ <%@>", [self stockShortDisplayInfo], self.currentPrice];
}

- (NSString *)currentPriceWithPercentage
{
    return self.currentPrice ? [NSString stringWithFormat:@"%@ (%@%%)", self.currentPrice, self.changePercentage] : @"-.-";
}

@end
