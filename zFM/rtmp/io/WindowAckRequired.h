//
//  WindowAckRequired.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpPacket.h"

@interface WindowAckRequired : NSObject

@property (nonatomic, strong) RtmpPacket *rtmpPacket;
@property (nonatomic, assign) int bytesRead;

@end
