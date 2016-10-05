//
//  Util.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Util.h"
#include <netinet/in.h>

@implementation Util

+ (int)setNonblock:(int)fd enabled:(BOOL)enabled {
    int flags = fcntl(fd, F_GETFL) & ~O_NONBLOCK;
    
    if (enabled) {
        flags |= O_NONBLOCK;
    }
    
    return fcntl(fd, F_SETFL, flags);
}

+ (size_t)readAll:(Stream*)inStream buf:(void*)buf len:(size_t)len {
    return [inStream readAll:buf len:len];
}

+ (size_t)writeAll:(Stream*)outStream buf:(void*)buf len:(size_t)len {
    return [outStream writeAll:buf len:len];
}

+ (BOOL)isSafe:(uint8_t)b {
    return b >= ' ' && b < 128;
}

+ (void)hexdump:(const void*)buf len:(size_t)len {
    const uint8_t *data = (const uint8_t *) buf;
    
    for (size_t i = 0; i < len; i += 16) {
        for (int j = 0; j < 16; ++j) {
            if (i + j < len) {
//                debug("%.2x ", data[i + j]);
            } else {
//                debug("   ");
            }
        }
        
        for (int j = 0; j < 16; ++j) {
            if (i + j < len) {
                char c = [Util isSafe:data[i + j]] ? data[i + j] : '.';
                putc(c, stdout);
            } else {
                putc(' ', stdout);
            }
        }
        putc('\n', stdout);
    }
}

+ (int)readUnsignedInt32:(Stream *)inStream {
    char buf[4] = {0, 0, 0, 0};
    [inStream readAll:buf len:sizeof(char) * 4];
    return ((buf[0] & 0xff) << 24) | ((buf[1] & 0xff) << 16) | ((buf[2] & 0xff) << 8) | (buf[3] & 0xff);
}

+ (int)readUnsignedInt24:(Stream *)inStream {
    char buf[3] = {0, 0, 0};
    [inStream readAll:buf len:sizeof(char) * 3];
    return ((buf[0] & 0xff) << 16) | ((buf[1] & 0xff) << 8) | (buf[2] & 0xff);
}

+ (int)readUnsignedInt16:(Stream *)inStream {
    char buf[2] = {0, 0};
    [inStream readAll:buf len:sizeof(char) * 2];
    return ((buf[0] & 0xff) << 8) | (buf[1] & 0xff);
}

+ (int)readUnsignedChar:(Stream *)inStream {
    char buf = 0;
    [inStream readAll:&buf len:sizeof(char)];
    return buf;
}

+ (void)writeUnsignedInt32:(Stream *)outStream value:(int)value {
    char buf[4] = {(char)(value >> 24), (char)(value >> 16), (char)(value >> 8), (char)value};
    [outStream writeAll:buf len:sizeof(char) * 4];
}

+ (void)writeUnsignedInt24:(Stream *)outStream value:(int)value {
    char buf[3] = {(char)(value >> 16), (char)(value >> 8), (char)value};
    [outStream writeAll:buf len:sizeof(char) * 3];
}

+ (void)writeUnsignedInt16:(Stream *)outStream value:(int)value {
    char buf[2] = {(char)(value >> 8), (char)value};
    [outStream writeAll:buf len:sizeof(char) * 2];
}

+ (void)writeUnsignedChar:(Stream *)outStream value:(int)value {
    char buf = (char)value;
    [outStream writeAll:&buf len:sizeof(char)];
}

+ (int)toUnsignedInt32:(char*)bytes {
    return (((int) bytes[0] & 0xff) << 24) | (((int)bytes[1] & 0xff) << 16) | (((int)bytes[2] & 0xff) << 8) | ((int)bytes[3] & 0xff);
}

+ (int)toUnsignedInt32LittleEndian:(char*)bytes {
    return ((bytes[3] & 0xff) << 24) | ((bytes[2] & 0xff) << 16) | ((bytes[1] & 0xff) << 8) | (bytes[0] & 0xff);
}

+ (void)writeUnsignedInt32LittleEndian:(Stream *)outStream value:(int)value {
    char buf[4] = {(char)value, (char)(value >> 8), (char)(value >> 16), (char)(value >> 24)};
    [outStream writeAll:buf len:sizeof(char) * 4];
}

+ (int)toUnsignedInt24:(char*)bytes {
    return ((bytes[1] & 0xff) << 16) | ((bytes[2] & 0xff) << 8) | (bytes[3] & 0xff);
}

+ (int)toUnsignedInt16:(char*)bytes {
    return ((bytes[2] & 0xff) << 8) | (bytes[3] & 0xff);
}

+ (NSString*)toHexString:(char*)raw len:(int)len {
    if (raw == NULL) {
        return nil;
    }
    
    static char HEXES[16] = "0123456789ABCDEF";
    
    NSMutableString *hex = [[NSMutableString alloc] initWithCapacity:2 * len];
    for (int i = 0; i < len; ++i) {
        char b = raw[i];
        [hex appendFormat:@"%c%c", HEXES[(b & 0xF0) >> 4], HEXES[(b & 0x0F) >> 4]];
    }
    return hex;
}

+ (NSString*)toHexString:(char)b {
    static char HEXES[16] = "0123456789ABCDEF";
    NSMutableString *hex = [[NSMutableString alloc] initWithCapacity:2 * 1];
    [hex appendFormat:@"%c%c", HEXES[(b & 0xF0) >> 4], HEXES[(b & 0x0F) >> 4]];
    return hex;
}


+ (void)readBytesUntilFull:(Stream *)inStream targetBuffer:(char *)targetBuffer len:(int)len {
    [inStream readAll:targetBuffer len:len];
}

+ (char*)toByteArray:(double)d {
    long l = (long)d;
    char *buf = malloc(sizeof(char) * 8);
    buf[0] = (char)((l >> 56) & 0xff),
    buf[1] = (char)((l >> 48) & 0xff),
    buf[2] = (char)((l >> 40) & 0xff),
    buf[3] = (char)((l >> 32) & 0xff),
    buf[4] = (char)((l >> 24) & 0xff),
    buf[5] = (char)((l >> 16) & 0xff),
    buf[6] = (char)((l >> 8) & 0xff),
    buf[7] = (char)(l & 0xff);
    return buf;
    return NULL;
}

+ (char*)unsignedInt32ToByteArray:(int)value {
    char *buf = malloc(sizeof(char) * 4);
    buf[0] = (char)(value >> 24);
    buf[1] = (char)(value >> 16);
    buf[2] = (char)(value >> 8);
    buf[3] = (char)value;
    return buf;
}

+ (double)readDouble:(Stream *)inStream {
    char buf[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    [inStream readAll:buf len:sizeof(char) * 8];
    long bits = ((long) (buf[0] & 0xff) << 56) | ((long) (buf[1] & 0xff) << 48) | ((long) (buf[2] & 0xff) << 40) | ((long) (buf[3] & 0xff) << 32) | ((buf[4] & 0xff) << 24) | ((buf[5] & 0xff) << 16) | ((buf[6] & 0xff) << 8) | (buf[7] & 0xff);
    return (double)bits;
}

+ (void)writeDouble:(Stream *)outStream value:(double)v {
    long l = (long)v;
    char buf[8] = {(char) ((l >> 56) & 0xff), (char) ((l >> 48) & 0xff), (char) ((l >> 40) & 0xff), (char) ((l >> 32) & 0xff), (char) ((l >> 24) & 0xff), (char) ((l >> 16) & 0xff), (char) ((l >> 8) & 0xff), (char) (l & 0xff)};
    [outStream writeAll:buf len:sizeof(char) * 8];
}

@end
