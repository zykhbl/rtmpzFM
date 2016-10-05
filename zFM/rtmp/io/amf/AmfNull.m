//
//  AmfNull.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfNull.h"
#import "Util.h"

@implementation AmfNull

- (void)writeTo:(Stream*)outStream {
    char type = NULLL;
    [Util writeAll:outStream buf:&type len:sizeof(char)];
}

- (void)readFrom:(Stream*)inStream {
    
}

+ (void)writeNullTo:(Stream*)outStream {
    char type = NULLL;
    [Util writeAll:outStream buf:&type len:sizeof(char)];
}

- (int)getSize {
    return 1;
}

@end
