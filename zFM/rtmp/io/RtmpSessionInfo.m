//
//  RtmpSessionInfo.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpSessionInfo.h"
#import "rtmp.h"

@implementation RtmpSessionInfo

@synthesize windowBytesRead;
@synthesize acknowledgementWindowSize;
@synthesize totalBytesRead;
@synthesize rxChunkSize;
@synthesize txChunkSize;
@synthesize chunkChannels;
@synthesize invokedMethods;

- (id)init {
    self = [super init];
    
    if (self) {
        self.acknowledgementWindowSize = INT64_MAX;
        self.totalBytesRead = 0;
        self.rxChunkSize = CHUNKSIZE;
        self.txChunkSize = CHUNKSIZE;
        self.chunkChannels = [[NSMutableDictionary alloc] init];
        self.invokedMethods = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (ChunkStreamInfo*)getChunkStreamInfo:(int)chunkStreamId {
    NSNumber *chStreamId = [[NSNumber alloc] initWithInt:chunkStreamId];
    
    ChunkStreamInfo *chunkStreamInfo = [self.chunkChannels objectForKey:chStreamId];
    if (chunkStreamInfo == nil) {
        chunkStreamInfo = [[ChunkStreamInfo alloc] init];
        [self.chunkChannels setObject:chunkStreamInfo forKey:chStreamId];
    }
    
    return chunkStreamInfo;
}

- (NSString*)takeInvokedCommand:(int)transactionId {
    NSNumber *tId = [[NSNumber alloc] initWithInt:transactionId];
    NSString *command = [NSString stringWithString:[self.invokedMethods objectForKey:tId]];
    [self.invokedMethods removeObjectForKey:tId];
    
    return command;
}

- (void)addInvokedCommand:(int)transactionId commandName:(NSString*)commandName {
    NSNumber *tId = [[NSNumber alloc] initWithInt:transactionId];
    [self.invokedMethods setObject:commandName forKey:tId];
}

//public final void addToWindowBytesRead(final int numBytes, final RtmpPacket packet) throws WindowAckRequired {
//    windowBytesRead += numBytes;
//    totalBytesRead += numBytes;
//    if (windowBytesRead >= acknowledgementWindowSize) {
//        windowBytesRead -= acknowledgementWindowSize;
//        throw new WindowAckRequired(totalBytesRead, packet);
//    }
//}

@end
