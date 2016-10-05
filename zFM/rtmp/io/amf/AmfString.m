//
//  AmfString.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfString.h"
#import "Util.h"

@implementation AmfString

@synthesize value;
@synthesize key;
@synthesize size;

- (id)initWithValue:(NSString*)str key:(BOOL)k {
    self = [super init];
    
    if (self) {
        self.value = [NSString stringWithString:str];
        self.key = k;
    }
    
    return self;
}

- (void)writeTo:(Stream*)outStream {
    if (!self.key) {
        char type = STRING;
        [Util writeAll:outStream buf:&type len:sizeof(char)];
    }
    
    NSData *data = [self.value dataUsingEncoding:NSASCIIStringEncoding];
    [Util writeUnsignedInt16:outStream value:data.length];
    [Util writeAll:outStream buf:(void*)data.bytes len:data.length];
}

- (void)readFrom:(Stream*)inStream {
    int length = [Util readUnsignedInt16:inStream];
    char *byteValue = malloc(sizeof(char) * (length + 1));
    [Util readBytesUntilFull:inStream targetBuffer:byteValue len:length];
    byteValue[length] = '\0';
    self.value = [NSString stringWithCString:byteValue encoding:NSASCIIStringEncoding];
    free(byteValue);
}

+ (NSString*)readFrom:(Stream*)inStream key:(BOOL)k {
    if (!k) {
        char type = 0;
        [Util readAll:inStream buf:&type len:sizeof(char)];
    }
    int length = [Util readUnsignedInt16:inStream];
    char *byteValue = malloc(sizeof(char) * (length + 1));
    [Util readBytesUntilFull:inStream targetBuffer:byteValue len:length];
    byteValue[length] = '\0';
    NSString *str = [NSString stringWithCString:byteValue encoding:NSASCIIStringEncoding];
    free(byteValue);
    return str;
}

+ (void)writeStringTo:(Stream*)outStream string:(NSString*)str key:(BOOL)k {
    if (!k) {
        char type = STRING;
        [Util writeAll:outStream buf:&type len:sizeof(char)];
    }
    
    NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
    [Util writeUnsignedInt16:outStream value:data.length];
    [Util writeAll:outStream buf:(void*)data.bytes len:data.length];
}

- (int)getSize {
    if (self.size == 0) {
        NSData *data = [self.value dataUsingEncoding:NSASCIIStringEncoding];
        self.size = (self.key ? 0 : 1) + 2 + data.length;
    }
    return self.size;
}

+ (int)sizeOf:(NSString*)str key:(BOOL)k {
    NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
    return (k ? 0 : 1) + 2 + data.length;
}

@end
