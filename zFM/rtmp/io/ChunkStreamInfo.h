//
//  ChunkStreamInfo.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BytesStream.h"

@class RtmpHeader;

#define RTMP_STREAM_CHANNEL     0x05
#define RTMP_COMMAND_CHANNEL    0x03
#define RTMP_VIDEO_CHANNEL      0x06
#define RTMP_AUDIO_CHANNEL      0x07
#define RTMP_CONTROL_CHANNEL    0x02

@interface ChunkStreamInfo : NSObject

@property (nonatomic, strong) RtmpHeader *prevHeaderRx;
@property (nonatomic, strong) RtmpHeader *prevHeaderTx;
@property (nonatomic, assign) long realLastTimestamp;
@property (nonatomic, strong) BytesStream *baos;

+ (void)markSessionTimestampTx;

- (BOOL)canReusePrevHeaderTx:(char)forMessageType;
- (long)markAbsoluteTimestampTx;
- (long)markDeltaTimestampTx;
- (int)storePacketChunk:(Stream*)inStream chunkSize:(int)chunkSize;
- (BytesStream*)getStoredPacketInputStream;
- (void)clearStoredChunks;

@end
