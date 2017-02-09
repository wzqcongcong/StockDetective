//
//  CCPointInfo.h
//  CoreChart2D
//
//  Created by GoKu on 9/5/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCPointInfo : NSObject

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger graph;
@property (nonatomic, assign) NSInteger element;

@end
