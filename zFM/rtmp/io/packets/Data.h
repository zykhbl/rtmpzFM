//
//  Data.h
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VariableBodyRtmpPacket.h"

@interface Data : VariableBodyRtmpPacket

@property (nonatomic, strong) NSString *type;

- (id)initWithType:(NSString*)t;

@end
