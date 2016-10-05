//
//  RtmpDecoder.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpDecoder.h"
#import "Command.h"
#import "Data.h"
#import "Audio.h"
#import "Video.h"

@implementation RtmpDecoder

@synthesize rtmpSessionInfo;

- (RtmpPacket*)readPacket:(Stream*)inStream {
again:
    RtmpHeader *header = [[RtmpHeader alloc] init];
    if (![header readHeaderImpl:inStream rtmpSessionInfo:self.rtmpSessionInfo]) {
        return nil;
    }
    
    ChunkStreamInfo *chunkStreamInfo = [self.rtmpSessionInfo getChunkStreamInfo:header.chunkStreamId];
    chunkStreamInfo.prevHeaderRx = header;
    
    if (header.packetLength > self.rtmpSessionInfo.rxChunkSize) {
        // If the packet consists of more than one chunk,
        // store the chunks in the chunk stream until everything is read
        int flag = [chunkStreamInfo storePacketChunk:inStream chunkSize:self.rtmpSessionInfo.rxChunkSize];
        if (flag == -1) {
            // return null because of incomplete packet
            return nil;
        } else if (flag == 0) {
            if ([(BytesStream*)inStream length] > 0) {
                goto again;
            } else {
                return nil;
            }
        } else if (flag == 1) {
            // stored chunks complete packet, get the input stream of the chunk stream
            inStream = [chunkStreamInfo getStoredPacketInputStream];
        }
    } else {
        if ([(BytesStream*)inStream length] < header.packetLength) {//不够解整个chunk包时，把当前chunk header的已读字节放回inStream
            [(BytesStream*)inStream reset:[header getHeaderLength] + 1];
            return nil;
        }
    }
    
    RtmpPacket *rtmpPacket = nil;
    switch (header.messageType) {
        case SET_CHUNK_SIZE:
//            SetChunkSize setChunkSize = new SetChunkSize(header);
//            setChunkSize.readBody(in);
//            Log.d(TAG, "readPacket(): Setting chunk size to: " + setChunkSize.getChunkSize());
//            self.rtmpSessionInfo.setRxChunkSize(setChunkSize.getChunkSize());
            return nil;
        case ABORT:
//            rtmpPacket = new Abort(header);
            break;
        case USER_CONTROL_MESSAGE:
//            rtmpPacket = new UserControl(header);
            break;
        case WINDOW_ACKNOWLEDGEMENT_SIZE:
//            rtmpPacket = new WindowAckSize(header);
            break;
        case SET_PEER_BANDWIDTH:
//            rtmpPacket = new SetPeerBandwidth(header);
            break;
        case AUDIO:
            rtmpPacket = [[Audio alloc] init];
            break;
        case VIDEO:
            rtmpPacket = [[Video alloc] init];
            break;
        case COMMAND_AMF3:
            rtmpPacket = [[Command alloc] init];
            rtmpPacket.header.messageType = COMMAND_AMF3;
            break;
        case COMMAND_AMF0:
            rtmpPacket = [[Command alloc] init];
            break;
        case DATA_AMF0:
            rtmpPacket = [[Data alloc] init];
            break;
        case ACKNOWLEDGEMENT:
//            rtmpPacket = new Acknowledgement(header);
            break;
        default:
            NSLog(@"No packet body implementation for message type: %c", header.messageType);
    }
    rtmpPacket.header = header;
    [rtmpPacket readBody:inStream];
    return rtmpPacket;
}

@end
