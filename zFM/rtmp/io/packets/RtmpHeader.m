//
//  RtmpHeader.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpHeader.h"
#import "Util.h"
#import "BytesStream.h"

@implementation RtmpHeader

@synthesize chunkType;
@synthesize chunkStreamId;
@synthesize absoluteTimestamp;
@synthesize timestampDelta;
@synthesize packetLength;
@synthesize messageType;
@synthesize messageStreamId;
@synthesize extendedTimestamp;

- (id)init:(char)chType chStreamId:(int)chStreamId mType:(char)mType {
    self = [super init];
    
    if (self) {
        self.chunkType = chType;
        self.chunkStreamId = chStreamId;
        self.messageType = mType;
        self.timestampDelta = -1;
    }
    
    return self;
}

- (int)getHeaderLength {
    int headerLens[4] = {11, 7, 3, 0};
    
    if (self.chunkType >= 0 && self.chunkType < 4) {
        return headerLens[self.chunkType];
    } else {
        exit(-1);//正确的方式应该关闭当前Client
    }    
}

- (BOOL)readHeaderImpl:(Stream*)inStream rtmpSessionInfo:(RtmpSessionInfo*)rtmpSessionInfo {
    if ([(BytesStream*)inStream length] <= 0) {//不够解整个包中包头的第一个字节时，返回等待，应该不会出现这种情况
        return NO;
    }
    
    char basicHeaderByte = 0;
    [Util readAll:inStream buf:&basicHeaderByte len:sizeof(char)];// Read byte 0: chunk type and chunk stream ID

    [self parseBasicHeader:basicHeaderByte];
    
    if ([(BytesStream*)inStream length] < [self getHeaderLength]) {//不够解整个包的包头时，把当前已读的包头中的第一个字节放回inStream
        [(BytesStream*)inStream reset:sizeof(char)];
        return NO;
    }
    
    switch (self.chunkType) {
        case TYPE_0_FULL: { //  b00 = 12 byte header (full header)
            self.absoluteTimestamp = [Util readUnsignedInt24:inStream];// Read bytes 1-3: Absolute timestamp
            self.timestampDelta = 0;
            self.packetLength = [Util readUnsignedInt24:inStream];// Read bytes 4-6: Packet length
            self.messageType = [Util readUnsignedChar:inStream];// Read byte 7: Message type ID
            char messageStreamIdBytes[4] = {0};
            [Util readBytesUntilFull:inStream targetBuffer:messageStreamIdBytes len:sizeof(char) * 4];
            self.messageStreamId = [Util toUnsignedInt32LittleEndian:messageStreamIdBytes];// Read bytes 8-11: Message stream ID (apparently little-endian order)
            self.extendedTimestamp = self.absoluteTimestamp >= 0xffffff ? [Util readUnsignedInt32:inStream] : 0;// Read bytes 1-4: Extended timestamp
            if (self.extendedTimestamp != 0) {
                self.absoluteTimestamp = self.extendedTimestamp;
            }
            break;
        }
        case TYPE_1_RELATIVE_LARGE: { // b01 = 8 bytes - like type 0. not including message stream ID (4 last bytes)
            self.timestampDelta = [Util readUnsignedInt24:inStream];// Read bytes 1-3: Timestamp delta
            self.packetLength = [Util readUnsignedInt24:inStream];// Read bytes 4-6: Packet length
            self.messageType = [Util readUnsignedChar:inStream];// Read byte 7: Message type ID
            self.extendedTimestamp = self.timestampDelta >= 0xffffff ? [Util readUnsignedInt32:inStream] : 0;// Read bytes 1-4: Extended timestamp delta
            RtmpHeader *prevHeader = [rtmpSessionInfo getChunkStreamInfo:self.chunkStreamId].prevHeaderRx;
            if (prevHeader != nil) {
                self.messageStreamId = prevHeader.messageStreamId;
                self.absoluteTimestamp = self.extendedTimestamp != 0 ? self.extendedTimestamp : prevHeader.absoluteTimestamp + self.timestampDelta;
            } else {
                self.messageStreamId = 0;
                self.absoluteTimestamp = self.extendedTimestamp != 0 ? self.extendedTimestamp : self.timestampDelta;
            }
            break;
        }
        case TYPE_2_RELATIVE_TIMESTAMP_ONLY: { // b10 = 4 bytes - Basic Header and timestamp (3 bytes) are included
            self.timestampDelta = [Util readUnsignedInt24:inStream];// Read bytes 1-3: Timestamp delta
            self.extendedTimestamp = self.timestampDelta >= 0xffffff ? [Util readUnsignedInt32:inStream] : 0;// Read bytes 1-4: Extended timestamp delta
            RtmpHeader *prevHeader = [rtmpSessionInfo getChunkStreamInfo:self.chunkStreamId].prevHeaderRx;
            self.packetLength = prevHeader.packetLength;
            self.messageType = prevHeader.messageType;
            self.messageStreamId = prevHeader.messageStreamId;
            self.absoluteTimestamp = self.extendedTimestamp != 0 ? self.extendedTimestamp : prevHeader.absoluteTimestamp + self.timestampDelta;
            break;
        }
        case TYPE_3_RELATIVE_SINGLE_BYTE: { // b11 = 1 byte: basic header only
            self.extendedTimestamp = self.timestampDelta >= 0xffffff ? [Util readUnsignedInt32:inStream] : 0;// Read bytes 1-4: Extended timestamp
            RtmpHeader *prevHeader = [rtmpSessionInfo getChunkStreamInfo:self.chunkStreamId].prevHeaderRx;
            self.timestampDelta = self.extendedTimestamp != 0 ? 0xffffff : prevHeader.timestampDelta;
            self.packetLength = prevHeader.packetLength;
            self.messageType = prevHeader.messageType;
            self.messageStreamId = prevHeader.messageStreamId;
            self.absoluteTimestamp = self.extendedTimestamp != 0 ? self.extendedTimestamp : prevHeader.absoluteTimestamp + self.timestampDelta;
            break;
        }
        default: {
            NSLog(@"readHeaderImpl(): Invalid chunk type; basic header byte was:%@", [Util toHexString:basicHeaderByte]);
            exit(-1);//正确的方式应该关闭当前Client
        }
    }
    
    return YES;
}

- (void)writeTo:(Stream*)outStream chunkType:(char)switchChunkType chunkStreamInfo:(ChunkStreamInfo*)chunkStreamInfo {// Write basic header byte
    [Util writeUnsignedChar:outStream value:(char)(switchChunkType << 6) | self.chunkStreamId];
    switch (switchChunkType) {
        case TYPE_0_FULL: { //  b00 = 12 byte header (full header)
            [chunkStreamInfo markDeltaTimestampTx];
            [Util writeUnsignedInt24:outStream value:self.absoluteTimestamp >= 0xffffff ? 0xffffff : self.absoluteTimestamp];
            [Util writeUnsignedInt24:outStream value:self.packetLength];
            [Util writeUnsignedChar:outStream value:self.messageType];
            [Util writeUnsignedInt32LittleEndian:outStream value:self.messageStreamId];
            if (self.absoluteTimestamp >= 0xffffff) {
                self.extendedTimestamp = self.absoluteTimestamp;
                [Util writeUnsignedInt32:outStream value:self.extendedTimestamp];
            }
            break;
        }
        case TYPE_1_RELATIVE_LARGE: { // b01 = 8 bytes - like type 0. not including message ID (4 last bytes)
            self.timestampDelta = (int) [chunkStreamInfo markDeltaTimestampTx];
            self.absoluteTimestamp = chunkStreamInfo.prevHeaderTx.absoluteTimestamp + self.timestampDelta;
            [Util writeUnsignedInt24:outStream value:self.absoluteTimestamp >= 0xffffff ? 0xffffff : self.timestampDelta];
            [Util writeUnsignedInt24:outStream value:self.packetLength];
            [Util writeUnsignedChar:outStream value:self.messageType];
            if (self.absoluteTimestamp >= 0xffffff) {
                self.extendedTimestamp = self.absoluteTimestamp;
                [Util writeUnsignedInt32:outStream value:self.extendedTimestamp];
            }
            break;
        }
        case TYPE_2_RELATIVE_TIMESTAMP_ONLY: { // b10 = 4 bytes - Basic Header and timestamp (3 bytes) are included
            self.timestampDelta = (int) [chunkStreamInfo markDeltaTimestampTx];
            self.absoluteTimestamp = chunkStreamInfo.prevHeaderTx.absoluteTimestamp + self.timestampDelta;
            [Util writeUnsignedInt24:outStream value:self.absoluteTimestamp >= 0xffffff ? 0xffffff : self.timestampDelta];
            if (self.absoluteTimestamp >= 0xffffff) {
                self.extendedTimestamp = self.absoluteTimestamp;
                [Util writeUnsignedInt32:outStream value:self.extendedTimestamp];
            }
            break;
        }
        case TYPE_3_RELATIVE_SINGLE_BYTE: { // b11 = 1 byte: basic header only
            self.timestampDelta = (int) [chunkStreamInfo markDeltaTimestampTx];
            self.absoluteTimestamp = chunkStreamInfo.prevHeaderTx.absoluteTimestamp + self.timestampDelta;
            if (self.absoluteTimestamp >= 0xffffff) {
                self.extendedTimestamp = self.absoluteTimestamp;
                [Util writeUnsignedInt32:outStream value:self.extendedTimestamp];
            }
            break;
        }
        default: {
            NSLog(@"Invalid chunk type:%c", self.chunkType);
            break;
        }
    }
}

- (void)parseBasicHeader:(char)basicHeaderByte {
    self.chunkType = (0xff & basicHeaderByte) >> 6;
    self.chunkStreamId = basicHeaderByte & 0x3F;
}

@end
