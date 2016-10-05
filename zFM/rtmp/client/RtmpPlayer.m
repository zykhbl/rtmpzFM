//
//  RtmpPlayer.m
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpPlayer.h"
#import "AmfNull.h"

@implementation RtmpPlayer

- (id)init {
    self = [super init];
    
    if (self) {
        self.logPrevStr = @"RtmpPlayer";
        self.type = PLAY;
    }
    
    return self;
}

- (void)play {
    if (!self.connected) {
        NSLog(@"%@ not connected to RTMP server", self.logPrevStr);
        return;
    }
    
    if (self.currentStreamId == 0) {
        NSLog(@"%@ no current stream object exists", self.logPrevStr);
        return;
    }
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    NSLog(@"%@ play(): Sending play command...", self.logPrevStr);
    Command *playInvoke = [[Command alloc] init:@"play" transactionId:0];// transactionId == 0
    playInvoke.header.messageType = COMMAND_AMF3;
    playInvoke.header.chunkStreamId = RTMP_STREAM_CHANNEL;
    playInvoke.header.messageStreamId = self.currentStreamId;
    [playInvoke addData:[[AmfNull alloc] init]];
    [playInvoke addDataOfDouble:1];
    [self sendRtmpPacket:playInvoke toClient:client];
}

@end
