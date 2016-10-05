//
//  RtmpSessionInfo.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChunkStreamInfo.h"

@interface RtmpSessionInfo : NSObject

@property (nonatomic, assign) int windowBytesRead;
@property (nonatomic, assign) int acknowledgementWindowSize;
@property (nonatomic, assign) int totalBytesRead;

@property (nonatomic, assign) int rxChunkSize;
@property (nonatomic, assign) int txChunkSize;
@property (nonatomic, strong) NSMutableDictionary *chunkChannels;
@property (nonatomic, strong) NSMutableDictionary *invokedMethods;

- (ChunkStreamInfo*)getChunkStreamInfo:(int)chunkStreamId;
- (NSString*)takeInvokedCommand:(int)transactionId;
- (void)addInvokedCommand:(int)transactionId commandName:(NSString*)commandName;

@end
