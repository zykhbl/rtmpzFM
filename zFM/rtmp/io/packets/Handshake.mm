//
//  Handshake.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "Handshake.h"

@implementation Handshake

@synthesize hs;

- (void)dealloc {
    if (self.hs != NULL) {
        free(self.hs);
    }
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.hs = (HandshakeStruct*)malloc(sizeof(HandshakeStruct));
        memset(self.hs, 0, sizeof(HandshakeStruct));
    }
    
    return self;
}

@end
