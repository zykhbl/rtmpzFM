//
//  RtmpServer.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpServer.h"
#import "HandshakeS2C.h"
#import "BytesStream.h"
#import "AmfObject.h"
#import "AmfString.h"
#import "AmfNull.h"
#import "AmfNumber.h"
#import "AmfMap.h"
#import "Data.h"
#import "Audio.h"

@implementation RtmpServer

@synthesize listen_fd;
@synthesize publishers;

- (id)init {
    self = [super init];
    
    if (self) {
        self.pm = [[PollManager alloc] initWithCapacity:100];
        self.logPrevStr = @"server";
        self.publishers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)handshake {
    struct sockaddr_in sin;
    socklen_t addrlen = sizeof sin;
    int fd = accept(listen_fd, (struct sockaddr *) &sin, &addrlen);
    if (fd < 0) {
        NSLog(@"%@ Unable to accept a client: %s\n", self.logPrevStr, strerror(errno));
    }
    
    Client *c = [[Client alloc] init];
    c.stream.fd = fd;
    
    HandshakeS2C *hs = [[HandshakeS2C alloc] init];
    [hs handshake:c.stream];//??出错时未 close(fd);

    [Util setNonblock:c.stream.fd enabled:YES];
    
    [self.pm addPollClient:c];
}

- (void)handleConnect:(Command*)invoke toClient:(Client*)client {
    ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
	Command *connectResultInvoke = [[Command alloc] init:@"_result" transactionId:invoke.transactionId channelInfo:chunkStreamInfo];
    connectResultInvoke.header.messageStreamId = 0;
    
    AmfObject *infoData = [[AmfObject alloc] init];
    
    AmfObject *data = [[AmfObject alloc] init];
    [data setProperty:@"srs_server_ip" string:@"FMS/4,5,1,484"];
    [data setProperty:@"srs_pid" numberInt:255];
    [data setProperty:@"srs_id" numberInt:1.0];
    [infoData setProperty:@"data" amfData:data];
    
    [connectResultInvoke addData:infoData];
    
	[self sendRtmpPacket:connectResultInvoke toClient:client];
    
    NSLog(@"%@ send to c:connect result", self.logPrevStr);
}

- (void)handleFCPublish:(Command*)invoke toClient:(Client*)client {
	NSLog(@"%@ publisher connected", self.logPrevStr);
    
    AmfString *streamName = [invoke.data objectAtIndex:1];
	NSLog(@"%@ fcpublish %@", self.logPrevStr, streamName.value);
    
    Command *onFCPublishInvoke = [[Command alloc] init:@"onFCPublish" transactionId:0];
    onFCPublishInvoke.header.messageStreamId = 0;
    AmfObject *status = [[AmfObject alloc] init];
    [status setProperty:@"code" string:@"NetStream.Publish.Start"];
    [status setProperty:@"description" string:streamName.value];
    [onFCPublishInvoke addData:[[AmfNull alloc] init]];
    [onFCPublishInvoke addData:status];
    [self sendRtmpPacket:onFCPublishInvoke toClient:client];
    
    Command *FCPublishResultInvoke = [[Command alloc] init:@"_result" transactionId:invoke.transactionId];
    FCPublishResultInvoke.header.messageStreamId = 0;
    [FCPublishResultInvoke addData:[[AmfNull alloc] init]];
    [self sendRtmpPacket:FCPublishResultInvoke toClient:client];
}

- (void)handleCreateStream:(Command*)invoke toClient:(Client*)client {
    ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
	Command *createResultInvoke = [[Command alloc] init:@"_result" transactionId:invoke.transactionId channelInfo:chunkStreamInfo];
    createResultInvoke.header.messageStreamId = 0;
    
    static int STREAMID = 1;
    client.streamId = STREAMID;
    [createResultInvoke addData:[[AmfNumber alloc] initWithValue:STREAMID++]];
    
    [self sendRtmpPacket:createResultInvoke toClient:client];
}

- (void)handlePublish:(Command*)invoke toClient:(Client*)client {
    AmfString *streamName = [invoke.data objectAtIndex:1];
	NSLog(@"%@ publish %@", self.logPrevStr, streamName.value);
    
    client.isPublisher = YES;
    client.listeners = [[NSMutableArray alloc] init];
    
    [self.publishers addObject:client];
    
    ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
	Command *onStatusInvoke = [[Command alloc] init:@"onStatus" transactionId:0];
    onStatusInvoke.header.messageStreamId = chunkStreamInfo.prevHeaderRx.messageStreamId;
    AmfObject *status = [[AmfObject alloc] init];
    [status setProperty:@"level" string:@"status"];
    [status setProperty:@"code" string:@"NetStream.Publish.Start"];
    [status setProperty:@"description" string:@"Stream is now published"];
    [status setProperty:@"details" string:streamName.value];
    [onStatusInvoke addData:status];
    [self sendRtmpPacket:onStatusInvoke toClient:client];
    
    Command *publishResultInvoke = [[Command alloc] init:@"_result" transactionId:invoke.transactionId];
    publishResultInvoke.header.messageStreamId = 0;
    [publishResultInvoke addData:[[AmfNull alloc] init]];
    [self sendRtmpPacket:publishResultInvoke toClient:client];
}

- (void)handlePlay:(Command*)invoke toClient:(Client*)client {
    AmfNumber *streamId = [invoke.data objectAtIndex:1];
	NSLog(@"%@ play streamId: %d", self.logPrevStr, (int)streamId.value);
    
    {
        ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
        Command *onStatusInvoke = [[Command alloc] init:@"onStatus" transactionId:0];
        onStatusInvoke.header.messageStreamId = chunkStreamInfo.prevHeaderRx.messageStreamId;
        AmfObject *status = [[AmfObject alloc] init];
        [status setProperty:@"level" string:@"status"];
        [status setProperty:@"code" string:@"NetStream.Play.Reset"];
        [status setProperty:@"description" string:@"Resetting and playing stream"];
        [onStatusInvoke addData:status];
        [self sendRtmpPacket:onStatusInvoke toClient:client];
    }
    
    {
        ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
        Command *onStatusInvoke = [[Command alloc] init:@"onStatus" transactionId:0];
        onStatusInvoke.header.messageStreamId = chunkStreamInfo.prevHeaderRx.messageStreamId;
        AmfObject *status = [[AmfObject alloc] init];
        [status setProperty:@"level" string:@"status"];
        [status setProperty:@"code" string:@"NetStream.Play.Start"];
        [status setProperty:@"description" string:@"Started playing"];
        [onStatusInvoke addData:status];
        [self sendRtmpPacket:onStatusInvoke toClient:client];
    }
    
	client.playing = YES;
    
    for (Client *publisher in self.publishers) {
        if (publisher.streamId == (int)streamId.value && publisher.metadata != nil) {
            [publisher.listeners addObject:client];
            Data *metadata = [[Data alloc] initWithType:@"setDataFrame"];
            metadata.header.messageStreamId = client.streamId;
            [metadata.data addObjectsFromArray:publisher.metadata];
            [self sendRtmpPacket:metadata toClient:client];
        }
    }
}

- (void)handlePlay2:(Command*)invoke toClient:(Client*)client {
    
}

- (void)handlePause:(Command*)invoke toClient:(Client*)client {
    
}

- (void)handleRxInvoke:(Command*)invoke toClient:(Client*)client {
    if (invoke.header.messageStreamId == 0) {
        if ([invoke.commandName isEqualToString:@"connect"]) {
            [self handleConnect:invoke toClient:client];
        } else if ([invoke.commandName isEqualToString:@"FCPublish"]) {
            [self handleFCPublish:invoke toClient:client];
        } else if ([invoke.commandName isEqualToString:@"createStream"]) {
            [self handleCreateStream:invoke toClient:client];
        }
    } else {
        if ([invoke.commandName isEqualToString:@"publish"]) {
            [self handlePublish:invoke toClient:client];
        } else if ([invoke.commandName isEqualToString:@"play"]) {
            [self handlePlay:invoke toClient:client];
        } else if ([invoke.commandName isEqualToString:@"play2"]) {
            [self handlePlay2:invoke toClient:client];
        } else if ([invoke.commandName isEqualToString:@"pause"]) {
            [self handlePause:invoke toClient:client];
        }
    }
}

- (void)setDataFrame:(Data*)data toClient:(Client*)client {
	AmfString *onMetaData = [data.data objectAtIndex:0];
	if (![onMetaData.value isEqualToString:@"onMetaData"]) {
        NSLog(@"%@ can only set metadata", self.logPrevStr);
        return;
	}
    
    client.metadata = [[NSMutableArray alloc] initWithArray:data.data];
   
    for (Client *c in client.listeners) {
        if (c.playing) {
            Data *metadata = [[Data alloc] initWithType:@"setDataFrame"];
            metadata.header.messageStreamId = c.streamId;
            [metadata.data addObjectsFromArray:client.metadata];
            [self sendRtmpPacket:metadata toClient:c];
        }
    }
}

- (void)handleRxRtmpPacket:(RtmpPacket*)rtmpPacket toClient:(Client*)client {
    switch (rtmpPacket.header.messageType) {
        case AUDIO:
            if (client.isPublisher) {
                for (Client *c in client.listeners) {
                    if (c.playing) {
                        [self sendRtmpPacket:rtmpPacket toClient:c];
                    }
                }
            }
            break;
        case DATA_AMF0:
			if (client.isPublisher) {
				if ([((Data*)rtmpPacket).type isEqualToString:@"setDataFrame"]) {
					[self setDataFrame:(Data*)rtmpPacket toClient:client];
				}
			}
            break;
        case COMMAND_AMF3:
        case COMMAND_AMF0:
            [self handleRxInvoke:(Command*)rtmpPacket toClient:client];
            break;
        default:
            NSLog(@"%@ handleRxPacketLoop(): Not handling unimplemented/unknown packet of type: %c", self.logPrevStr, rtmpPacket.header.messageType);
            break;
    }
}

- (void)listen {
    self.listen_fd = socket(AF_INET, SOCK_STREAM, 0);
	if (self.listen_fd < 0) {
		return;
    }
    
	struct sockaddr_in sin;
	sin.sin_family = AF_INET;
	sin.sin_port = htons(PORT);
    sin.sin_addr.s_addr = htonl(INADDR_ANY);
//	sin.sin_addr.s_addr = inet_addr([addr cStringUsingEncoding:NSUTF8StringEncoding]);
	if (bind(self.listen_fd, (struct sockaddr *) &sin, sizeof sin) < 0) {
		NSLog(@"%@ unable to listen: %s", self.logPrevStr, strerror(errno));
		return;
	}
    
	listen(self.listen_fd, 10);
    
    [self.pm addPollInfo:self.listen_fd events:POLLIN flag:NO];
}

@end
