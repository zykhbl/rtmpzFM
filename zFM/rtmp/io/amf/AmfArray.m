//
//  AmfArray.m
//  zFM
//
//  Created by zykhbl on 16-9-27.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfArray.h"
#import "Util.h"
#import "AmfDecoder.h"

@implementation AmfArray

@synthesize items;
@synthesize size;

- (id)init {
    self = [super init];
    
    if (self) {
        self.items = [[NSMutableArray alloc] init];
        self.size = -1;
    }
    
    return self;
}

- (void)writeTo:(Stream*)outStream {
    NSLog(@"Not supported yet.");
}

- (void)readFrom:(Stream*)inStream {
    // Skip data type byte (we assume it's already read)
    int length = [Util readUnsignedInt32:inStream];
    self.size = 5; // 1 + 4

    for (int i = 0; i < length; ++i) {
        AmfData *dataItem = [AmfDecoder readFrom:inStream];
        self.size += [dataItem getSize];
        [self.items addObject:dataItem];
    }
}

- (int)getSize {
    if (self.size == -1) {
        self.size = 5; // 1 + 4
        if (self.items != nil) {
            for (AmfData *dataItem in self.items) {
                self.size += [dataItem getSize];
            }
        }
    }
    return self.size;
}

- (int)getLength {
    return self.items != nil ? self.items.count : 0;
}

- (void)addItem:(AmfData*)dataItem {
    [self.items addObject:dataItem];
}

@end
