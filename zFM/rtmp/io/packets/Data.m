//
//  Data.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Data.h"
#import "AmfString.h"

@implementation Data

@synthesize type;

- (id)initWithType:(NSString*)t {
    self = [super init];
    
    if (self) {
        self.header = [[RtmpHeader alloc] init];
        self.header.chunkType = TYPE_0_FULL;
        self.header.chunkStreamId = RTMP_COMMAND_CHANNEL;
        self.header.messageType = DATA_AMF0;
        self.type = t;
    }
    
    return self;
}

- (void)readBody:(Stream*)inStream {
    // Read notification type
    self.type = [AmfString readFrom:inStream key:NO];
    int bytesRead = [AmfString sizeOf:self.type key:NO];
    // Read data body
    [self readVariableData:inStream bytesAlreadyRead:bytesRead];
}

- (void)writeBody:(Stream*)outStream {
    [AmfString writeStringTo:outStream string:self.type key:NO];
    [self writeVariableData:outStream];
}

@end
