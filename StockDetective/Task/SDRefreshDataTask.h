//
//  SDRefreshDataTask.h
//  StockDetective
//
//  Created by GoKu on 7/25/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>


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
              stockCode:(NSString *)stockCode
      completionHandler:(void (^)(NSData *data))completionHandler;

@end
