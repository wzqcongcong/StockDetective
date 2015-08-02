//
//  SDStockInfo.h
//  StockDetective
//
//  Created by GoKu on 8/2/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kStockTypeSH    @"SH"
#define kStockTypeSZ    @"SZ"

#define kStockCodeDaPan @"大盘"

@interface SDStockInfo : NSObject

@property (nonatomic, strong) NSString *stockCode;
@property (nonatomic, strong) NSString *stockName;
@property (nonatomic, strong) NSString *stockAbbr;
@property (nonatomic, strong) NSString *stockType;

- (NSString *)stockShortDisplayInfo;

@end
