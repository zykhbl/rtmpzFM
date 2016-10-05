//
//  Audio.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Audio.h"

@implementation Audio

- (id)init {
    self = [super init];
    
    if (self) {
        self.header = [[RtmpHeader alloc] init];
        self.header.chunkType = TYPE_0_FULL;
        self.header.chunkStreamId = RTMP_AUDIO_CHANNEL;
        self.header.messageType = AUDIO;
    }
    
    return self;
}

- (NSString*)toString {
    return @"RTMP Audio";
}

@end
