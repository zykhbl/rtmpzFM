//
//  BytesStream.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2015年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stream.h"

@interface BytesStream : Stream

@property (nonatomic, assign) int readOffset;
@property (nonatomic, strong) NSMutableData *data;

- (id)initWithBytesStream:(BytesStream*)stream;
- (int)length;
- (void)reset:(int)count;
- (void)afterDecodedRtmpPacket;

@end
