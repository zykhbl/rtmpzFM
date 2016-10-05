//
//  Util.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stream.h"

@interface Util : NSObject

+ (int)setNonblock:(int)fd enabled:(BOOL)enabled;
+ (size_t)readAll:(Stream*)inStream buf:(void*)buf len:(size_t)len;
+ (size_t)writeAll:(Stream*)outStream buf:(void*)buf len:(size_t)len;
+ (BOOL)isSafe:(uint8_t)b;
+ (void)hexdump:(const void*)buf len:(size_t)len;
+ (int)readUnsignedInt32:(Stream*)inStream;
+ (int)readUnsignedInt24:(Stream*)inStream;
+ (int)readUnsignedInt16:(Stream*)inStream;
+ (int)readUnsignedChar:(Stream*)inStream;
+ (void)writeUnsignedInt32:(Stream*)outStream value:(int)value;
+ (void)writeUnsignedInt24:(Stream*)outStream value:(int)value;
+ (void)writeUnsignedInt16:(Stream*)outStream value:(int)value;
+ (void)writeUnsignedChar:(Stream*)outStream value:(int)value;
+ (int)toUnsignedInt32:(char*)bytes;
+ (int)toUnsignedInt32LittleEndian:(char*)bytes;
+ (void)writeUnsignedInt32LittleEndian:(Stream*)outStream value:(int)value;
+ (int)toUnsignedInt24:(char*)bytes;
+ (int)toUnsignedInt16:(char*)bytes;
+ (NSString*)toHexString:(char*)raw len:(int)len;
+ (NSString*)toHexString:(char)b;
+ (void)readBytesUntilFull:(Stream*)inStream targetBuffer:(char*)targetBuffer len:(int)len;
+ (char*)toByteArray:(double)d;
+ (char*)unsignedInt32ToByteArray:(int)value;
+ (double)readDouble:(Stream*)inStream;
+ (void)writeDouble:(Stream*)outStream value:(double)v;

@end
