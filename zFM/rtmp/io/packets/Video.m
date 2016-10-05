//
//  Video.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Video.h"

@implementation Video

- (id)init {
    self = [super init];
    
    if (self) {
        self.header = [[RtmpHeader alloc] init];
        self.header.chunkType = TYPE_0_FULL;
        self.header.chunkStreamId = RTMP_VIDEO_CHANNEL;
        self.header.messageType = VIDEO;
    }
    
    return self;
}

- (NSString*)toString {
    return @"RTMP Video";
}

@end
