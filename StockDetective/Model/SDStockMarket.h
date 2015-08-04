//
//  SDStockMarket.h
//  StockDetective
//
//  Created by GoKu on 8/4/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDStockInfo.h"

@interface SDStockMarket : SDStockInfo

@property (nonatomic, strong) NSString *currentPrice;

- (instancetype)init;
- (instancetype)initWithStockInfo:(SDStockInfo *)stockInfo;

@end
