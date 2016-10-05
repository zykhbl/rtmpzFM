//
//  RtmpDecoder.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpSessionInfo.h"
#import "RtmpPacket.h"

@interface RtmpDecoder : NSObject

@property (nonatomic, strong) RtmpSessionInfo *rtmpSessionInfo;

- (RtmpPacket*)readPacket:(Stream*)inStream;

@end
