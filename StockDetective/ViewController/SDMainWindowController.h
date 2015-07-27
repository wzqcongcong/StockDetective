//
//  SDMainWindowController.h
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SDMainWindowController : NSWindowController

- (void)updateViewWithStockCode:(NSString *)stockCode data:(NSData *)data;

@end
