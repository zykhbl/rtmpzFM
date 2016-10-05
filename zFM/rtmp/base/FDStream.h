//
//  FDStream.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stream.h"

@interface FDStream : Stream

@property (nonatomic, assign) int fd;

@end
