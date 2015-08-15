//
//  SDUtilities.m
//  StockDetective
//
//  Created by GoKu on 8/15/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDUtilities.h"

@interface SDUtilities ()

@property (nonatomic, strong) NSCache *sharedStockDataCache;

@end

@implementation SDUtilities

+ (BOOL)isStockMarketOnBusiness
{
    return NO;
}

@end
