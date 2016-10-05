//
//  ContentData.h
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpPacket.h"

@interface ContentData : RtmpPacket

@property (nonatomic, strong) NSMutableData *data;

@end
