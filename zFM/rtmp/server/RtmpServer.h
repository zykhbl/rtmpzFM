//
//  RtmpServer.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpNetwork.h"

@interface RtmpServer : RtmpNetwork

@property (nonatomic, assign) int listen_fd;
@property (nonatomic, strong) NSMutableArray *publishers;

- (void)listen;

@end
