//
//  RtmpPacket.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpHeader.h"

@interface RtmpPacket : NSObject

@property (nonatomic, strong) RtmpHeader *header;

- (void)readBody:(Stream*)inStream;
- (void)writeBody:(Stream*)outStream;

@end
