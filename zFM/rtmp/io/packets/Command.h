//
//  Command.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VariableBodyRtmpPacket.h"

/**
 * Encapsulates an command/"invoke" RTMP packet
 *
 * Invoke/command packet structure (AMF encoded):
 * (String) <commmand name>
 * (Number) <Transaction ID>
 * (Mixed) <Argument> ex. Null, String, Object: {key1:value1, key2:value2 ... }
 *
 */
@interface Command : VariableBodyRtmpPacket

@property (nonatomic, strong) NSString *commandName;
@property (nonatomic, assign) int transactionId;

- (id)init:(NSString*)cn transactionId:(int)tId channelInfo:(ChunkStreamInfo*)channelInfo;
- (id)init:(NSString*)cn transactionId:(int)tId;

@end
