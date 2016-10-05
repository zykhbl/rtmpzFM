//
//  RtmpConnection.h
//  zFM
//
//  Created by zykhbl on 16-9-28.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpNetwork.h"
#import "AmfNumber.h"
#import "AmfString.h"

typedef enum {
	PUBLISH,
	PLAY
} RtmpType;

@protocol RtmpConnectionDelegate;

@interface RtmpConnection : RtmpNetwork

@property (nonatomic, assign) id<RtmpConnectionDelegate> delegate;
@property (nonatomic, assign) RtmpType type;
@property (nonatomic, assign) int transactionIdCounter;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) NSString *srsServerInfo;
@property (nonatomic, strong) AmfString *serverIpAddr;
@property (nonatomic, strong) AmfNumber *serverPid;
@property (nonatomic, strong) AmfNumber *serverId;
@property (nonatomic, assign) int currentStreamId;
@property (nonatomic, strong) NSString *streamName;
@property (nonatomic, assign) BOOL publishPermitted;

- (void)connect:(NSString*)addr;

- (void)fmlePublish;
- (void)onMetaData;
- (void)play;

@end


@protocol RtmpConnectionDelegate <NSObject>

@optional
- (void)RtmpConnection:(RtmpConnection*)connection beginStream:(BOOL)flag;

- (void)RtmpConnection:(RtmpConnection*)connection play:(Float64)mSampleRate mBitsPerChannel:(UInt32)mBitsPerChannel;
- (void)RtmpConnection:(RtmpConnection*)connection addAudioBuf:(const void*)inInputData numberBytes:(UInt32)inNumberBytes;

@end