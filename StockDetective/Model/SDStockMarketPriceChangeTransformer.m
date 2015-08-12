//
//  SDStockMarketPriceChangeTransformer.m
//  StockDetective
//
//  Created by user on 8/12/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDStockMarketPriceChangeTransformer.h"

@implementation SDStockMarketPriceChangeTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSString *str = value;
    return str ? [NSString stringWithFormat:@"(%.2f%%)", str.floatValue] : @"";
}

@end
