//
//  RtmpConnection.m
//  zFM
//
//  Created by zykhbl on 16-9-28.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpConnection.h"
#import "HandshakeC2S.h"
#import "ChunkStreamInfo.h"
#import "AmfObject.h"
#import "AmfNull.h"
#import "AmfMap.h"
#import "Data.h"
#import "Audio.h"

#define APPNAME         @"zFM"
#define SWFURL          @"zFM.com"
#define TCURL           @"zFM.com"
#define PAGEURL         @"zFM.com"
#define STREAMNAME      @"zFM"

@implementation RtmpConnection

@synthesize delegate;
@synthesize type;
@synthesize transactionIdCounter;
@synthesize connected;
@synthesize srsServerInfo;
@synthesize serverIpAddr;
@synthesize serverPid;
@synthesize serverId;
@synthesize currentStreamId;
@synthesize streamName;
@synthesize publishPermitted;

- (id)init {
    self = [super init];
    
    if (self) {
        self.pm = [[PollManager alloc] initWithCapacity:1];
        
        self.transactionIdCounter = 0;
        self.streamName = STREAMNAME;
    }
    
    return self;
}

- (void)connect:(NSString*)addr {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd < 0) {
		return;
    }
    
	struct sockaddr_in sin;
	sin.sin_family = AF_INET;
	sin.sin_port = htons(PORT);
	sin.sin_addr.s_addr = inet_addr([addr cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (connect(fd, (struct sockaddr *)&sin, sizeof(struct sockaddr_in)) != 0) {
        NSLog(@"%@ socket connect error!", self.logPrevStr);
        return;
    } else {
        NSLog(@"%@ connect!", self.logPrevStr);
    }
    
    [self.pm addPollInfo:fd events:POLLIN | POLLOUT flag:YES];
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    HandshakeC2S *hs = [[HandshakeC2S alloc] init];
    [hs handshake:client.stream];
    
    [Util setNonblock:client.stream.fd enabled:YES];
    
    [self rtmpConnect];
}

- (void)rtmpConnect {
    if (self.connected) {
        NSLog(@"%@ already connected to RTMP server", self.logPrevStr);
        return;
    }
    
    // Mark session timestamp of all chunk stream information on connection.
    [ChunkStreamInfo markSessionTimestampTx];
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    NSLog(@"%@ rtmpConnect(): Building 'connect' invoke packet", self.logPrevStr);
    ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
    Command *connectInvoke = [[Command alloc] init:@"connect" transactionId:++self.transactionIdCounter channelInfo:chunkStreamInfo];
    connectInvoke.header.messageStreamId = 0;
    
    AmfObject *args = [[AmfObject alloc] init];
    [args setProperty:@"app" string:APPNAME];
    [args setProperty:@"flashVer" string:@"LNX 11,2,202,233"];// Flash player OS: Linux, version: 11.2.202.233
    [args setProperty:@"swfUrl" string:SWFURL];
    [args setProperty:@"tcUrl" string:TCURL];
    [args setProperty:@"fpad" boolean:NO];
    [args setProperty:@"capabilities" numberInt:239];
    [args setProperty:@"audioCodecs" numberInt:3575];
//    [args setProperty:@"videoCodecs" numberInt:252];
//    [args setProperty:@"videoFunction" numberInt:1];
    [args setProperty:@"pageUrl" string:TCURL];
    [args setProperty:@"objectEncoding" numberInt:0];
    
    [connectInvoke addData:args];
    
    [self sendRtmpPacket:connectInvoke toClient:client];
//    mHandler.onRtmpConnecting("connecting");
}

- (void)createStream {
    if (!self.connected) {
        NSLog(@"%@ not connected to RTMP server", self.logPrevStr);
        return;
    }
    
    if (self.currentStreamId != 0) {
        NSLog(@"%@ current stream object has existed", self.logPrevStr);
        return;
    }
    
    Client *client = (__bridge Client *)(self.pm.clients[0]);
    
    NSLog(@"%@ createStream(): Sending releaseStream command...", self.logPrevStr);
    Command *releaseStreamInvoke = [[Command alloc] init:@"releaseStream" transactionId:++self.transactionIdCounter];// transactionId = 2
    releaseStreamInvoke.header.chunkStreamId = RTMP_STREAM_CHANNEL;
    [releaseStreamInvoke addData:[[AmfNull alloc] init]];
    [releaseStreamInvoke addDataOfString:self.streamName];
    [self sendRtmpPacket:releaseStreamInvoke toClient:client];
    
    NSLog(@"%@ createStream(): Sending FCPublish command...", self.logPrevStr);
    Command *FCPublishInvoke = [[Command alloc] init:@"FCPublish" transactionId:++self.transactionIdCounter];// transactionId = 3
    FCPublishInvoke.header.chunkStreamId = RTMP_STREAM_CHANNEL;
    [FCPublishInvoke addData:[[AmfNull alloc] init]];
    [FCPublishInvoke addDataOfString:self.streamName];
    [self sendRtmpPacket:FCPublishInvoke toClient:client];
    
    NSLog(@"%@ createStream(): Sending createStream command...", self.logPrevStr);
    ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:RTMP_COMMAND_CHANNEL];
    Command *createStreamInvoke = [[Command alloc] init:@"createStream" transactionId:++self.transactionIdCounter channelInfo:chunkStreamInfo];// transactionId = 4
    [createStreamInvoke addData:[[AmfNull alloc] init]];
    [self sendRtmpPacket:createStreamInvoke toClient:client];
}

- (void)closeStream {
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
    
    NSLog(@"%@ closeStream(): setting current stream ID to 0", self.logPrevStr);
    Command *closeStream = [[Command alloc] init:@"closeStream" transactionId:0];
    closeStream.header.chunkStreamId = RTMP_STREAM_CHANNEL;
    closeStream.header.messageStreamId = self.currentStreamId;
    [closeStream addData:[[AmfNull alloc] init]];
    [self sendRtmpPacket:closeStream toClient:client];
}

- (void)fmlePublish {
    
}

- (void)onMetaData {
    
}

- (void)play {
    
}

- (void)onSrsServerInfo:(Command*)invoke {// SRS server special information
    AmfObject *objData = (AmfObject*)[invoke.data objectAtIndex:0];
    AmfData *amfData = [objData getProperty:@"data"];
    if ([amfData isKindOfClass:[AmfObject class]]) {
        AmfObject *amfObject = (AmfObject*)amfData;
        self.serverIpAddr = (AmfString*)[amfObject getProperty:@"srs_server_ip"];
        self.serverPid = (AmfNumber*)[amfObject getProperty:@"srs_pid"];
        self.serverId = (AmfNumber*)[amfObject getProperty:@"srs_id"];
    }
    NSString *ipAddStr = self.serverIpAddr == nil ? @"" : [NSString stringWithFormat:@"ip: %@", self.serverIpAddr.value];
    NSString *pidStr = self.serverPid == nil ? @"" : [NSString stringWithFormat:@"pid: %d", (int)self.serverPid.value];
    NSString *idStr = self.serverId == nil ? @"" : [NSString stringWithFormat:@"id: %d", (int)self.serverId.value];
    self.srsServerInfo = [NSString stringWithFormat:@"%@%@%@", ipAddStr, pidStr, idStr];
}

- (void)handleRxInvoke:(Command*)invoke toClient:(Client*)client {
    if ([invoke.commandName isEqualToString:@"_result"]) {
        NSString *method = [client.rtmpSessionInfo takeInvokedCommand:invoke.transactionId];// This is the result of one of the methods invoked by us
        
        NSLog(@"%@ handleRxInvoke: Got result for invoked method: %@", self.logPrevStr, method);
        if ([method isEqualToString:@"connect"]) {
            [self onSrsServerInfo:invoke];// Capture server ip/pid/id information if any
            self.connected = YES;
            
            [self createStream];
        } else if ([method isEqualToString:@"createStream"]) {
            self.currentStreamId = (int)((AmfNumber*)[invoke.data objectAtIndex:0]).value;// Get stream id
            if (self.type == PUBLISH) {
                NSLog(@"%@ handleRxInvoke(): Stream ID to publish: %d", self.logPrevStr, self.currentStreamId);
                [self fmlePublish];
            } else if (self.type == PLAY) {
                NSLog(@"%@ handleRxInvoke(): Stream ID to play: %d", self.logPrevStr, self.currentStreamId);
                [self play];
            }
        } else if ([method isEqualToString:@"releaseStream"]) {
            NSLog(@"%@ handleRxInvoke(): 'releaseStream'", self.logPrevStr);
        } else if ([method isEqualToString:@"FCPublish"]) {
            NSLog(@"%@ handleRxInvoke(): 'FCPublish'", self.logPrevStr);
        } else {
            NSLog(@"%@ handleRxInvoke(): '_result' message received for unknown method: %@", self.logPrevStr, method);
        }
    } else if ([invoke.commandName isEqualToString:@"onBWDone"]) {
        NSLog(@"%@ handleRxInvoke(): 'onBWDone'", self.logPrevStr);
    } else if ([invoke.commandName isEqualToString:@"onFCPublish"]) {
        NSLog(@"%@ handleRxInvoke(): 'onFCPublish'", self.logPrevStr);
    } else if ([invoke.commandName isEqualToString:@"onStatus"]) {
        if (self.type == PUBLISH) {
            NSString *code = ((AmfString*)([(AmfObject*)[invoke.data objectAtIndex:0] getProperty:@"code"])).value;
            NSLog(@"%@ handleRxInvoke(): onStatus: %@", self.logPrevStr, code);
            if ([code isEqualToString:@"NetStream.Publish.Start"]) {
                [self onMetaData];
                self.publishPermitted = true;
                
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(RtmpConnection:beginStream:)]) {
                    [self.delegate RtmpConnection:self beginStream:YES];
                }
            }
        } else if (self.type == PLAY) {
            NSString *code = ((AmfString*)([(AmfObject*)[invoke.data objectAtIndex:0] getProperty:@"code"])).value;
            NSLog(@"%@ handleRxInvoke(): onStatus: %@", self.logPrevStr, code);
            if ([code isEqualToString:@"NetStream.Play.Start"]) {
                
            }
        }
    } else {
        NSLog(@"%@ handleRxInvoke(): Unknown/unhandled server invoke: %@", self.logPrevStr, invoke.commandName);
    }
}

- (void)handleRxRtmpPacket:(RtmpPacket*)rtmpPacket toClient:(Client*)client {
    switch (rtmpPacket.header.messageType) {
//        case ABORT:
//            rtmpSessionInfo.getChunkStreamInfo(((Abort) rtmpPacket).getChunkStreamId()).clearStoredChunks();
//            break;
//        case USER_CONTROL_MESSAGE:
//            UserControl user = (UserControl) rtmpPacket;
//            switch (user.getType()) {
//                case STREAM_BEGIN:
//                    if (currentStreamId != user.getFirstEventData()) {
//                        throw new IllegalStateException("Current stream ID error!");
//                    }
//                    break;
//                case PING_REQUEST:
//                    ChunkStreamInfo channelInfo = rtmpSessionInfo.getChunkStreamInfo(ChunkStreamInfo.RTMP_CONTROL_CHANNEL);
//                    Log.d(TAG, "handleRxPacketLoop(): Sending PONG reply..");
//                    UserControl pong = new UserControl(user, channelInfo);
//                    sendRtmpPacket(pong);
//                    break;
//                case STREAM_EOF:
//                    Log.i(TAG, "handleRxPacketLoop(): Stream EOF reached, closing RTMP writer...");
//                    break;
//                default:
//                    // Ignore...
//                    break;
//            }
//            break;
//        case WINDOW_ACKNOWLEDGEMENT_SIZE:
//            WindowAckSize windowAckSize = (WindowAckSize) rtmpPacket;
//            int size = windowAckSize.getAcknowledgementWindowSize();
//            Log.d(TAG, "handleRxPacketLoop(): Setting acknowledgement window size: " + size);
//            rtmpSessionInfo.setAcknowledgmentWindowSize(size);
//            break;
//        case SET_PEER_BANDWIDTH:
//            SetPeerBandwidth bw = (SetPeerBandwidth) rtmpPacket;
//            rtmpSessionInfo.setAcknowledgmentWindowSize(bw.getAcknowledgementWindowSize());
//            int acknowledgementWindowsize = rtmpSessionInfo.getAcknowledgementWindowSize();
//            ChunkStreamInfo chunkStreamInfo = rtmpSessionInfo.getChunkStreamInfo(ChunkStreamInfo.RTMP_CONTROL_CHANNEL);
//            Log.d(TAG, "handleRxPacketLoop(): Send acknowledgement window size: " + acknowledgementWindowsize);
//            sendRtmpPacket(new WindowAckSize(acknowledgementWindowsize, chunkStreamInfo));
//            // Set socket option
//            socket.setSendBufferSize(acknowledgementWindowsize);
//            break;
        case AUDIO:
            if (self.type == PLAY) {
                if (self.delegate != nil && [self.delegate respondsToSelector:@selector(RtmpConnection:addAudioBuf:numberBytes:)]) {
                    Audio *audio = (Audio*)rtmpPacket;
                    [self.delegate RtmpConnection:self addAudioBuf:audio.data.bytes numberBytes:audio.data.length];
                }
            }
            break;
        case DATA_AMF0:
			if (self.type == PLAY) {
                Data *data = (Data*)rtmpPacket;
				if ([data.type isEqualToString:@"setDataFrame"]) {
                    AmfMap *ecmaMap = [data.data objectAtIndex:1];
                    Float64 audiosamplerate = ((AmfNumber*)[ecmaMap.properties valueForKey:@"audiosamplerate"]).value;
					UInt32 audiosamplesize = ((AmfNumber*)[ecmaMap.properties valueForKey:@"audiosamplesize"]).value;
                    
                    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(RtmpConnection:play:mBitsPerChannel:)]) {
                        [self.delegate RtmpConnection:self play:audiosamplerate mBitsPerChannel:audiosamplesize];
                    }
				}
			}
            break;
        case COMMAND_AMF0:
            [self handleRxInvoke:(Command*)rtmpPacket toClient:client];
            break;
        default:
            NSLog(@"%@ handleRxPacketLoop(): Not handling unimplemented/unknown packet of type: %c", self.logPrevStr, rtmpPacket.header.messageType);
            break;
    }
}

@end
