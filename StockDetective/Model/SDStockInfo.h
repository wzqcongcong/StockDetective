//
//  SDStockInfo.h
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSDStockCodeDaPan;
extern NSString * const kSDStockFullCodeDaPan;

extern NSString * const kSDStockTypeSH;
extern NSString * const kSDStockTypeSZ;

@interface SDStockInfo : NSObject

@property (nonatomic, strong) NSString *stockCode;
@property (nonatomic, strong) NSString *stockName;
@property (nonatomic, strong) NSString *stockAbbr;
@property (nonatomic, strong) NSString *stockType;

- (NSString *)stockShortDisplayInfo;

@end
