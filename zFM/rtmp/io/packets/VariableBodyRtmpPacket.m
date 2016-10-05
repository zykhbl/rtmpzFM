//
//  VariableBodyRtmpPacket.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "VariableBodyRtmpPacket.h"
#import "AmfDecoder.h"
#import "AmfNull.h"
#import "AmfBoolean.h"
#import "AmfNumber.h"
#import "AmfString.h"

@implementation VariableBodyRtmpPacket

@synthesize data;

- (id)init {
    self = [super init];
    
    if (self) {
        self.data = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addDataOfString:(NSString*)string {
    AmfString *amf = [[AmfString alloc] init];
    amf.value = string;
    [self addData:amf];
}

- (void)addDataOfDouble:(double)number {
    AmfNumber *amf = [[AmfNumber alloc] init];
    amf.value = number;
    [self addData:amf];
}

- (void)addDataOfBOOL:(BOOL)b {
    AmfBoolean *amf = [[AmfBoolean alloc] init];
    amf.value = b;
    [self addData:amf];
}

- (void)addData:(AmfData*)dataItem {
    if (dataItem == nil) {
        dataItem = [[AmfNull alloc] init];
    }
    [self.data addObject:dataItem];
}

- (void)readVariableData:(Stream*)inStream bytesAlreadyRead:(int)bytesAlreadyRead {
    do {
        AmfData *dataItem = [AmfDecoder readFrom:inStream];
        [self addData:dataItem];
        bytesAlreadyRead += [dataItem getSize];
    } while (bytesAlreadyRead < self.header.packetLength);
}

- (void)writeVariableData:(Stream*)outStream {
    if (self.data.count > 0) {
        for (int i = 0; i < [self.data count]; ++i) {
            AmfData *dataItem = [self.data objectAtIndex:i];
            [dataItem writeTo:outStream];
        }
    } else {
        [AmfNull writeNullTo:outStream];
    }
}

@end
