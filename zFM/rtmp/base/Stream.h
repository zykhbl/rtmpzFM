//
//  Stream.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Stream : NSObject

- (size_t)readAll:(void*)buf len:(size_t)len;
- (size_t)writeAll:(void*)buf len:(size_t)len;

@end
