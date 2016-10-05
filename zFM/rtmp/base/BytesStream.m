//
//  BytesStream.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2015年 zykhbl. All rights reserved.
//

#import "BytesStream.h"
#import "Util.h"

#define DELLIMIT        1024 * 10

@implementation BytesStream

@synthesize readOffset;
@synthesize data;

- (id)init {
    self = [super init];
    
    if (self) {
        self.readOffset = 0;
        self.data = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (id)initWithBytesStream:(BytesStream*)stream {
    self = [super init];
    
    if (self) {
        self.readOffset = 0;
        self.data = [[NSMutableData alloc] init];
        [self.data appendBytes:stream.data.bytes + stream.readOffset length:[stream length]];
    }
    
    return self;
}

- (int)length {
    return self.data.length - self.readOffset;
}

- (size_t)writeAll:(void*)buf len:(size_t)len {
    [self.data appendBytes:buf length:len];
    return len;
}

- (size_t)readAll:(void*)buf len:(size_t)len {
    memcpy(buf, self.data.bytes + self.readOffset, len);
    self.readOffset += len;
    return len;
}

- (void)reset:(int)count {
    self.readOffset -= count;
}

- (void)afterDecodedRtmpPacket {
    if (self.readOffset >= DELLIMIT) {
        NSMutableData *newData = [[NSMutableData alloc] init];
        if ([self length] > 0) {
            [newData appendBytes:self.data.bytes + self.readOffset length:[self length]];
        }
        
        self.data = nil;
        self.data = newData;        
        self.readOffset = 0;
    }
}

@end
