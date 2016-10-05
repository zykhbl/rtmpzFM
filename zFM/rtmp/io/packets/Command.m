//
//  Command.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Command.h"
#import "AmfString.h"
#import "AmfNumber.h"

@implementation Command

@synthesize commandName;
@synthesize transactionId;

- (id)init:(NSString*)cn transactionId:(int)tId channelInfo:(ChunkStreamInfo*)channelInfo {
    self = [super init];
    
    if (self) {
        self.header = [[RtmpHeader alloc] init];
        if ([channelInfo canReusePrevHeaderTx:COMMAND_AMF0] ) {
            self.header.chunkType = TYPE_1_RELATIVE_LARGE;
        } else {
            self.header.chunkType = TYPE_0_FULL;
        }
        self.header.chunkStreamId = RTMP_COMMAND_CHANNEL;
        self.header.messageType = COMMAND_AMF0;
        
        self.commandName = cn;
        self.transactionId = tId;
    }
    
    return self;
}

- (id)init:(NSString*)cn transactionId:(int)tId {
    self = [super init];
    
    if (self) {
        self.header = [[RtmpHeader alloc] init];
        self.header.chunkType = TYPE_0_FULL;
        self.header.chunkStreamId = RTMP_COMMAND_CHANNEL;
        self.header.messageType = COMMAND_AMF0;
        
        self.commandName = cn;
        self.transactionId = tId;
    }
    
    return self;
}

- (void)readBody:(Stream*)inStream {
    // The command name and transaction ID are always present (AMF string followed by number)
    self.commandName = [AmfString readFrom:inStream key:NO];
    self.transactionId = (int)[AmfNumber readNumberFrom:inStream];
    int bytesRead = [AmfString sizeOf:self.commandName key:NO] + AMFNUMBERSIZE;
    [self readVariableData:inStream bytesAlreadyRead:bytesRead];
}

- (void)writeBody:(Stream*)outStream {
    [AmfString writeStringTo:outStream string:self.commandName key:NO];
    [AmfNumber writeNumberTo:outStream number:self.transactionId];
    // Write body data
    [self writeVariableData:outStream];
}

- (NSString*)toString {
    return [NSString stringWithFormat:@"RTMP Command (command: %@, transaction ID: %d)", self.commandName, self.transactionId];
}

@end
