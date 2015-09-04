//
//  SDRefreshDataTask.h
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDStockInfo.h"

typedef NS_ENUM(NSUInteger, TaskType) {
    TaskTypeRealtime,
    TaskTypeHistory,
};

@protocol SDRefreshDataTaskManagerProtocol <NSObject>

@property (atomic, strong) NSDate *lastRefreshedByDataTaskStartDate; // renewed when a task successfully refresh the data

@end

@interface SDRefreshDataTask : NSObject

@property (nonatomic, weak) id<SDRefreshDataTaskManagerProtocol> taskManager;

- (void)refreshDataTask:(TaskType)taskType
              stockInfo:(SDStockInfo *)stockInfo
         successHandler:(void (^)(NSData *data))successHandler
         failureHandler:(void (^)(NSError *error))failureHandler;

@end
