//
//  Client.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Client.h"

@implementation Client

@synthesize stream;
@synthesize playing;
@synthesize ready;
@synthesize rtmpSessionInfo;
@synthesize rtmpDecoder;
@synthesize sendQueue;
@synthesize recvStream;
@synthesize mutex;
@synthesize isPublisher;
@synthesize metadata;
@synthesize listeners;

- (void)dealloc {
    pthread_mutex_destroy(&mutex);
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.playing = NO;
        self.ready = NO;
        
        self.stream = [[FDStream alloc] init];
        self.rtmpSessionInfo = [[RtmpSessionInfo alloc] init];
        self.rtmpDecoder = [[RtmpDecoder alloc] init];
        self.rtmpDecoder.rtmpSessionInfo = self.rtmpSessionInfo;
        
        self.sendQueue = [[NSMutableArray alloc] init];
        self.recvStream = [[BytesStream alloc] init];
        
        pthread_mutex_init(&mutex, NULL);
        
        self.isPublisher = NO;
        self.streamId = -1;
    }
    
    return self;
}

- (void)lock {
    pthread_mutex_lock(&mutex);
}

- (void)unlock {
    pthread_mutex_unlock(&mutex);
}

@end
