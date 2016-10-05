//
//  RtmpNetwork.h
//  zFM
//
//  Created by zykhbl on 16-9-28.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Util.h"
#include "rtmp.h"
#import "PollManager.h"
#import "Command.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@interface RtmpNetwork : NSObject

@property (nonatomic, strong) PollManager *pm;
@property (nonatomic, strong) NSString *logPrevStr;

- (void)startDoPollThread;

- (void)handshake;
- (void)sendRtmpPacket:(RtmpPacket*)rtmpPacket toClient:(Client*)client;
- (void)handleRxRtmpPacket:(RtmpPacket*)rtmpPacket toClient:(Client*)client;
- (void)doPoll;

@end
