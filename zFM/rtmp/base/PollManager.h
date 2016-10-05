//
//  PollManager.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Client.h"
#include <sys/poll.h>

@interface PollManager : NSObject

@property (nonatomic, assign) int pollSize;
@property (nonatomic, assign) int capacity;
@property (nonatomic, assign) struct pollfd *poll_table;
@property (nonatomic, assign) void **clients;

- (id)initWithCapacity:(int)c;

- (void)addPollInfo:(int)fd events:(short)events flag:(BOOL)flag;
- (void)addPollClient:(Client*)c;
- (void)deletePollInfo;

@end
