//
//  AmfUndefined.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfUndefined.h"

@implementation AmfUndefined

- (void)writeTo:(Stream*)outStream {
    char type = UNDEFINED;
    [outStream writeAll:&type len:sizeof(char)];
}

- (void)readFrom:(Stream*)inStream {
    // Skip data type byte (we assume it's already read)
}

+ (void)writeUndefinedTo:(Stream*)outStream {
    char type = UNDEFINED;
    [outStream writeAll:&type len:sizeof(char)];
}

- (int)getSize {
    return 1;
}

@end
