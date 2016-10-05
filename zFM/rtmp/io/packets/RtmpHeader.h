//
//  RtmpHeader.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpSessionInfo.h"
#import "Stream.h"

#define SET_CHUNK_SIZE                  0x01
#define ABORT                           0x02
#define ACKNOWLEDGEMENT                 0x03
#define USER_CONTROL_MESSAGE            0x04
#define WINDOW_ACKNOWLEDGEMENT_SIZE     0x05
#define SET_PEER_BANDWIDTH              0x06
#define AUDIO                           0x08
#define VIDEO                           0x09
#define DATA_AMF3                       0x0F
#define SHARED_OBJECT_AMF3              0x10
#define COMMAND_AMF3                    0x11
#define DATA_AMF0                       0x12
#define COMMAND_AMF0                    0x14
#define SHARED_OBJECT_AMF0              0x13
#define AGGREGATE_MESSAGE               0x16

#define TYPE_0_FULL                     0x00
#define TYPE_1_RELATIVE_LARGE           0x01
#define TYPE_2_RELATIVE_TIMESTAMP_ONLY  0x02
#define TYPE_3_RELATIVE_SINGLE_BYTE     0x03

@interface RtmpHeader : NSObject

@property (nonatomic, assign) char chunkType;
@property (nonatomic, assign) int chunkStreamId;
@property (nonatomic, assign) int absoluteTimestamp;
@property (nonatomic, assign) int timestampDelta;
@property (nonatomic, assign) int packetLength;
@property (nonatomic, assign) char messageType;
@property (nonatomic, assign) int messageStreamId;
@property (nonatomic, assign) int extendedTimestamp;

- (id)init:(char)chType chStreamId:(int)chStreamId mType:(char)mType;

- (int)getHeaderLength;
- (BOOL)readHeaderImpl:(Stream*)inStream rtmpSessionInfo:(RtmpSessionInfo*)rtmpSessionInfo;
- (void)writeTo:(Stream*)outStream chunkType:(char)switchChunkType chunkStreamInfo:(ChunkStreamInfo*)chunkStreamInfo;

@end
