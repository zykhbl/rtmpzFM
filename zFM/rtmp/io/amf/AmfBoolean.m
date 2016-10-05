//
//  AmfBoolean.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfBoolean.h"
#import "Util.h"

@implementation AmfBoolean

@synthesize value;

- (id)initWithValue:(BOOL)v {
    self = [super init];
    
    if (self) {
        self.value = v;
    }
    
    return self;
}

- (void)writeTo:(Stream*)outStream {
    char type = BOOLEAN;
    [Util writeAll:outStream buf:&type len:sizeof(char)];
    char v = self.value ? 0x01 : 0x00;
    [Util writeAll:outStream buf:&v len:sizeof(char)];
}

- (void)readFrom:(Stream*)inStream {
    self.value = [Util readUnsignedChar:inStream];
}

- (BOOL)readBooleanFrom:(Stream*)inStream {
    return [Util readUnsignedChar:inStream];
}

- (int)getSize {
    return 9;
}

@end
