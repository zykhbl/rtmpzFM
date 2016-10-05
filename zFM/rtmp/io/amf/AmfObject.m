//
//  AmfObject.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfObject.h"
#import "AmfNull.h"
#import "AmfBoolean.h"
#import "AmfNumber.h"
#import "AmfString.h"
#import "AmfDecoder.h"
#import "Util.h"
#import "BytesStream.h"

@implementation AmfObject

@synthesize properties;
@synthesize size;

- (id)init {
    self = [super init];
    
    if (self) {
        self.properties = [[NSMutableDictionary alloc] init];
        self.size = -1;
    }
    
    return self;
}

- (AmfData*)getProperty:(NSString*)key {
    return [self.properties objectForKey:key];
}

- (void)setProperty:(NSString*)key amfData:(AmfData*)amfData {
    [self.properties setObject:amfData forKey:key];
}

- (void)setProperty:(NSString*)key boolean:(BOOL)bl {
    [self.properties setObject:[[AmfBoolean alloc] initWithValue:bl] forKey:key];
}

- (void)setProperty:(NSString*)key string:(NSString*)str {
    [self.properties setObject:[[AmfString alloc] initWithValue:str key:NO] forKey:key];
}

- (void)setProperty:(NSString*)key numberInt:(int)intV {
    [self.properties setObject:[[AmfNumber alloc] initWithValue:intV] forKey:key];
}

- (void)setProperty:(NSString*)key numberDouble:(double)doubleV {
    [self.properties setObject:[[AmfNumber alloc] initWithValue:doubleV] forKey:key];
}

- (void)writeTo:(Stream*)outStream {
    // Begin the object
    char amfType = OBJECT;
    [Util writeAll:outStream buf:&amfType len:sizeof(char)];
    
    // Write key/value pairs in this object
    NSArray *keys = [self.properties allKeys];
    for (NSString *key in keys) {
        // The key must be a STRING type, and thus the "type-definition" byte is implied (not included in message)
        [AmfString writeStringTo:outStream string:key key:YES];
        
        AmfData *amfData = [self.properties objectForKey:key];
        [amfData writeTo:outStream];
    }
    
    // End the object
    char object_end_marker[3] = {0x00, 0x00, 0x09};
    [Util writeAll:outStream buf:object_end_marker len:sizeof(char) * 3];
}

- (void)readFrom:(Stream*)inStream {
    // Skip data type byte (we assume it's already read)
    self.size = 1;
    
    //如果inStream为FDStream，一定会出问题
    BytesStream *markInputStream = (BytesStream*)inStream;
    
    char object_end_marker[3] = {0x00, 0x00, 0x09};
    while (true) {
        // Look for the 3-byte object end marker [0x00 0x00 0x09]
        char endMarker[3] = {0};
        if (markInputStream.length >= 3) {
            [Util readAll:markInputStream buf:endMarker len:sizeof(char) * 3];
        }
        
        if (endMarker[0] == object_end_marker[0] && endMarker[1] == object_end_marker[1] && endMarker[2] == object_end_marker[2]) {// End marker found
            self.size += 3;
            return;
        } else {// End marker not found; reset the stream to the marked position and read an AMF property
            [markInputStream reset:3];
            // Read the property key...
            NSString *key = [AmfString readFrom:markInputStream key:YES];
            self.size += [AmfString sizeOf:key key:YES];
            // ...and the property value
            AmfData *amfData = [AmfDecoder readFrom:markInputStream];
            self.size += [amfData getSize];
            [self.properties setObject:amfData forKey:key];
        }
    }
}

- (int)getSize {
    if (self.size == -1) {
        self.size = 1; // object marker
        
        NSArray *keys = [self.properties allKeys];
        for (NSString *key in keys) {
            self.size += [AmfString sizeOf:key key:YES];
            
            AmfData *amfData = [self.properties objectForKey:key];
            self.size += [amfData getSize];
        }
        
        self.size += 3; // end of object marker
    }
    return self.size;
}

@end
