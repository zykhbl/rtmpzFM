//
//  VariableBodyRtmpPacket.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpPacket.h"
#import "AmfData.h"

@interface VariableBodyRtmpPacket : RtmpPacket

@property (nonatomic, strong) NSMutableArray *data;

- (void)addDataOfString:(NSString*)string;
- (void)addDataOfDouble:(double)number;
- (void)addDataOfBOOL:(BOOL)b;
- (void)addData:(AmfData*)dataItem;

- (void)readVariableData:(Stream*)inStream bytesAlreadyRead:(int)bytesAlreadyRead;
- (void)writeVariableData:(Stream*)outStream;

@end
