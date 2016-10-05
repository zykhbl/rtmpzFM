//
//  ChunkStreamInfo.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "ChunkStreamInfo.h"
#import "RtmpHeader.h"
#import "Util.h"

@implementation ChunkStreamInfo

@synthesize prevHeaderRx;
@synthesize prevHeaderTx;
@synthesize realLastTimestamp;
@synthesize baos;

- (id)init {
    self = [super init];
    if (self) {
        self.realLastTimestamp = [[NSDate new] timeIntervalSince1970] / 1000000;
        self.baos = [[BytesStream alloc] init];
    }
    
    return self;
}

static long sessionBeginTimestamp;

+ (void)markSessionTimestampTx {
    sessionBeginTimestamp = [[NSDate new] timeIntervalSince1970] / 1000000;
}

- (BOOL)canReusePrevHeaderTx:(char)forMessageType {
    return self.prevHeaderTx != nil && self.prevHeaderTx.messageType == forMessageType;
}

- (long)markAbsoluteTimestampTx {
     return [[NSDate new] timeIntervalSince1970] / 1000000 - sessionBeginTimestamp;
}

- (long)markDeltaTimestampTx {
    long currentTimestamp = [[NSDate new] timeIntervalSince1970] / 1000000;
    long diffTimestamp = currentTimestamp - self.realLastTimestamp;
    self.realLastTimestamp = currentTimestamp;
    return diffTimestamp;
}

- (int)storePacketChunk:(Stream*)inStream chunkSize:(int)chunkSize {
    int remainingBytes = self.prevHeaderRx.packetLength - [self.baos length];
    int size = MIN(remainingBytes, chunkSize);
    
    if ([(BytesStream*)inStream length] < size) {//不够解整个chunk包时，把当前chunk header的已读字节放回inStream
        [(BytesStream*)inStream reset:[self.prevHeaderRx getHeaderLength] + 1];
        return -1;
    }
    
    char *chunk = (char *)malloc(sizeof(char) * size);
    
    [Util readBytesUntilFull:inStream targetBuffer:chunk len:sizeof(char) * size];
    
    [self.baos writeAll:chunk len:size];
    free(chunk);
    
    if ([self.baos length] == self.prevHeaderRx.packetLength) {
        return 1;
    } else {
        return 0;
    }
}

- (BytesStream*)getStoredPacketInputStream {
    BytesStream *bis = [[BytesStream alloc] initWithBytesStream:self.baos];
    self.baos = [[BytesStream alloc] init];
    return bis;
}

- (void)clearStoredChunks {
    self.baos = [[BytesStream alloc] init];
}

@end
