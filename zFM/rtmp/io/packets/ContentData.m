//
//  ContentData.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "ContentData.h"
#import "Util.h"

@implementation ContentData

@synthesize data;

- (id)init {
    self = [super init];
    
    if (self) {
        self.data = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (void)readBody:(Stream*)inStream {
    int size = sizeof(char) * self.header.packetLength;
    char *buf = malloc(size);
    
    [Util readBytesUntilFull:inStream targetBuffer:buf len:size];
    [self.data appendBytes:buf length:size];
    
    free(buf);
}

- (void)writeBody:(Stream*)outStream {
    [outStream writeAll:(void*)self.data.bytes len:self.data.length];
}

@end
