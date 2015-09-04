//
//  SDStockInfo.h
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSDStockTypeSH;
extern NSString * const kSDStockTypeSZ;

extern NSString * const kSDStockHuZhiName;
extern NSString * const kSDStockHuZhiCode;
extern NSString * const kSDStockHuZhiAbbr;
extern NSString * const kSDStockHuZhiType;
extern NSString * const kSDStockHuZhiFullCode;

extern NSString * const kSDStockShenZhiName;
extern NSString * const kSDStockShenZhiCode;
extern NSString * const kSDStockShenZhiAbbr;
extern NSString * const kSDStockShenZhiType;
extern NSString * const kSDStockShenZhiFullCode;

@interface SDStockInfo : NSObject

@property (nonatomic, strong) NSString *stockCode;
@property (nonatomic, strong) NSString *stockName;
@property (nonatomic, strong) NSString *stockAbbr;
@property (nonatomic, strong) NSString *stockType;

- (instancetype)init;
- (instancetype)initHuZhi;
- (instancetype)initShenZhi;

- (BOOL)isValidStock;
- (NSString *)fullStockCode;
- (NSString *)stockShortDisplayInfo;
- (NSString *)stockShortDisplayInfoV2;

@end
