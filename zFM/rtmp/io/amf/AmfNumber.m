//
//  AmfNumber.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfNumber.h"
#import "Util.h"

@implementation AmfNumber

@synthesize value;

- (id)initWithValue:(double)v {
    self = [super init];
    
    if (self) {
        self.value = v;
    }
    
    return self;
}

- (void)writeTo:(Stream*)outStream {
    char type = NUMBER;
    [Util writeAll:outStream buf:&type len:sizeof(char)];
    [Util writeDouble:outStream value:self.value];
}

- (void)readFrom:(Stream*)inStream {
    self.value = [Util readDouble:inStream];
}

+ (double)readNumberFrom:(Stream*)inStream {
    char type = 0;
    [Util readAll:inStream buf:&type len:sizeof(char)];
    return [Util readDouble:inStream];
}

+ (void)writeNumberTo:(Stream*)outStream number:(double)number {
    char type = NUMBER;
    [Util writeAll:outStream buf:&type len:sizeof(char)];
    [Util writeDouble:outStream value:number];
}

- (int)getSize {
    return AMFNUMBERSIZE;
}

@end
