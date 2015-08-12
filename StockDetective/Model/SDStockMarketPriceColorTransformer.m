//
//  SDStockMarketPriceColorTransformer.m
//  StockDetective
//
//  Created by user on 8/12/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SDStockMarketPriceColorTransformer.h"
#import "SDStockMarket.h"
#import <Cocoa/Cocoa.h>

@implementation SDStockMarketPriceColorTransformer

+ (Class)transformedValueClass
{
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    NSString *changePercentage = value;
    if (!changePercentage) {
        return [NSColor labelColor];
    }

    if (changePercentage.floatValue > 0) {
        return [NSColor redColor];
    } else if (changePercentage.floatValue < 0) {
        return [NSColor greenColor];
    } else {
        return [NSColor labelColor];
    }
}

@end
