//
//  Handshake.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PROTOCOL_VERSION    0x03
#define HANDSHAKE_SIZE      1536
#define RANDOM_LEN          HANDSHAKE_SIZE - 8

typedef struct {
	uint8_t time[4];
    uint8_t zero[4];
	uint8_t random[RANDOM_LEN];
} HandshakeStruct;

@interface Handshake : NSObject

@property (nonatomic, assign) HandshakeStruct *hs;

@end
