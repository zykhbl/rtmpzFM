//
//  RtmpPublisher.m
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpPublisher.h"
#import "ChunkStreamInfo.h"
#import "AmfObject.h"
#import "AmfNull.h"
#import "AmfMap.h"
#import "Data.h"
#import "Audio.h"
#import "Video.h"
#import "rtmp.h"

#define PUBLISHTYPE     @"AUDIO"

@implementation RtmpPublisher

@synthesize publishType;

- (id)init {
    self = [super init];
    
    if (self) {
        self.logPrevStr = @"RtmpPublisher";
        self.type = PUBLISH;
        self.publishType = PUBLISHTYPE;
    }
    
    return self;
}

- (void)fmlePublish {
    if (!self.connected) {
        NSLog(@"%@ not connected to RTMP server", self.logPrevStr);
        return;
    }
    
    if (self.currentStreamId == 0) {
        NSLog(@"%@ no current stream object exists", self.logPrevStr);
        return;
    }
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    NSLog(@"%@ fmlePublish(): Sending publish command...", self.logPrevStr);
    Command *publishInvoke = [[Command alloc] init:@"publish" transactionId:0];// transactionId == 0
    publishInvoke.header.chunkStreamId = RTMP_STREAM_CHANNEL;
    publishInvoke.header.messageStreamId = self.currentStreamId;
    [publishInvoke addData:[[AmfNull alloc] init]];
    [publishInvoke addDataOfString:self.streamName];
    [publishInvoke addDataOfString:self.publishType];
    [self sendRtmpPacket:publishInvoke toClient:client];
}

- (void)onMetaData {
    if (!self.connected) {
        NSLog(@"%@ not connected to RTMP server", self.logPrevStr);
        return;
    }
    
    if (self.currentStreamId == 0) {
        NSLog(@"%@ no current stream object exists", self.logPrevStr);
        return;
    }
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    NSLog(@"%@ onMetaData(): Sending empty onMetaData...", self.logPrevStr);
    Data *metadata = [[Data alloc] initWithType:@"setDataFrame"];
    metadata.header.messageStreamId = self.currentStreamId;
    [metadata addDataOfString:@"onMetaData"];
    AmfMap *ecmaMap = [[AmfMap alloc] init];
    [ecmaMap setProperty:@"duration" numberInt:0];
//    [ecmaMap setProperty:@"width" numberInt:0];
//    [ecmaMap setProperty:@"height" numberInt:0];
//    [ecmaMap setProperty:@"videodatarate" numberInt:0];
    [ecmaMap setProperty:@"framerate" numberInt:0];
    [ecmaMap setProperty:@"audiodatarate" numberInt:0];
    [ecmaMap setProperty:@"audiosamplerate" numberInt:SAMPLERATE];
    [ecmaMap setProperty:@"audiosamplesize" numberInt:BITSPERCHANNEL];
    [ecmaMap setProperty:@"stereo" boolean:YES];
    [ecmaMap setProperty:@"filesize" numberInt:0];
    [metadata addData:ecmaMap];
    [self sendRtmpPacket:metadata toClient:client];
}

- (void)publishAudioData:(NSMutableData*)data dts:(int)dts {
    if (!self.connected) {
        NSLog(@"%@ not connected to RTMP server", self.logPrevStr);
        return;
    }
    
    if (self.currentStreamId == 0) {
        NSLog(@"%@ no current stream object exists", self.logPrevStr);
        return;
    }
    
    if (!self.publishPermitted) {
        NSLog(@"%@ not get _result(Netstream.Publish.Start)", self.logPrevStr);
        return;
    }
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    Audio *audio = [[Audio alloc] init];
    audio.data = data;
    audio.header.absoluteTimestamp = dts;
    audio.header.messageStreamId = self.currentStreamId;
    [self sendRtmpPacket:audio toClient:client];
}

- (void)publishVideoData:(NSMutableData*)data dts:(int)dts {
    if (!self.connected) {
        NSLog(@"%@ not connected to RTMP server", self.logPrevStr);
        return;
    }
    
    if (self.currentStreamId == 0) {
        NSLog(@"%@ no current stream object exists", self.logPrevStr);
        return;
    }
    
    if (!self.publishPermitted) {
        NSLog(@"%@ not get _result(Netstream.Publish.Start)", self.logPrevStr);
        return;
    }
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    Video *video = [[Video alloc] init];
    video.data = data;
    video.header.absoluteTimestamp = dts;
    video.header.messageStreamId = self.currentStreamId;
    [self sendRtmpPacket:video toClient:client];
}

@end
