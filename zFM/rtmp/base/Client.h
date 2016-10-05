//
//  Client.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FDStream.h"
#import "RtmpDecoder.h"
#include <pthread.h>

@interface Client : NSObject

@property (nonatomic, strong) FDStream *stream;
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) BOOL ready;
@property (nonatomic, strong) RtmpSessionInfo *rtmpSessionInfo;
@property (nonatomic, strong) RtmpDecoder *rtmpDecoder;
@property (nonatomic, strong) NSMutableArray *sendQueue;
@property (nonatomic, strong) BytesStream *recvStream;
@property (nonatomic, assign) pthread_mutex_t mutex;

@property (nonatomic, assign) BOOL isPublisher;
@property (nonatomic, assign) int streamId;
@property (nonatomic, strong) NSMutableArray *metadata;
@property (nonatomic, strong) NSMutableArray *listeners;


//	size_t chunk_len;
//	uint32_t written_seq;
//	uint32_t read_seq;

- (void)lock;
- (void)unlock;

@end
