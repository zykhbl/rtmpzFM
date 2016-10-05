//
//  AmfMap.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfMap.h"
#import "Util.h"
#import "AmfString.h"

@implementation AmfMap

- (void)writeTo:(Stream*)outStream {
    // Begin the map/object/array/whatever exactly this is
    char type = MAP;
    [outStream writeAll:&type len:sizeof(char)];
    
    // Write the "array size"
    [Util writeUnsignedInt32:outStream value:self.properties.count];
    
    // Write key/value pairs in this object
    NSArray *allKeys = [self.properties allKeys];
    for (NSString *key in allKeys) {
        // The key must be a STRING type, and thus the "type-definition" byte is implied (not included in message)
        [AmfString writeStringTo:outStream string:key key:YES];
        [(AmfData*)[self.properties objectForKey:key] writeTo:outStream];
    }
    
    // End the object
    char object_end_marker[3] = {0x00, 0x00, 0x09};
    [outStream writeAll:object_end_marker len:sizeof(char) * 3];
}

- (void)readFrom:(Stream*)inStream {
    // Skip data type byte (we assume it's already read)
    [Util readUnsignedInt32:inStream]; // Seems this is always 0
    [super readFrom:inStream];
    self.size += 4; // Add the bytes read for parsing the array size (length)
}

- (int)getSize {
    if (self.size == -1) {
        self.size = [super getSize];
        self.size += 4; // array length bytes
    }
    return self.size;
}

@end
