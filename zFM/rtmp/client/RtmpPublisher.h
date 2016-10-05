//
//  RtmpPublisher.h
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpConnection.h"

@interface RtmpPublisher : RtmpConnection

@property (nonatomic, strong) NSString *publishType;

- (void)publishAudioData:(NSMutableData*)data dts:(int)dts;

@end
