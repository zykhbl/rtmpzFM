//
//  HandshakeS2C.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "HandshakeS2C.h"
#import "Util.h"

@implementation HandshakeS2C

@synthesize c1;
@synthesize s1;

- (void)recvC0:(Stream*)stream {
    int8_t c0 = 0;
    
    if ([Util readAll:stream buf:&c0 len:1] < 1) {
        NSLog(@"handshake: recvC0 error!\n");
        exit(-1);
    }
    
    if (c0 != PROTOCOL_VERSION) {
        if (c0 == -1) {
            NSLog(@"handshake: recvC0 error(InputStream closed)!\n");
        } else {
            NSLog(@"handshake: recvC0 error(Invalid RTMP protocol version; expected %d, got %d)!\n", PROTOCOL_VERSION, c0);
        }
        
        exit(-1);
    }
}

- (void)sendS0:(Stream*)stream {
    int8_t s0 = (int8_t)PROTOCOL_VERSION;
    
    if ([Util writeAll:stream buf:&s0 len:1] < 1) {
        NSLog(@"handshake: sendS0 error!\n");
        exit(-1);
    }
}

- (void)sendS1:(Stream*)stream {
    self.s1 = [[Handshake alloc] init];
	self.s1.hs->time[0] = (int8_t)PROTOCOL_VERSION;  //??为什么不是0
    
	for (int i = 0; i < RANDOM_LEN; ++i) {
		self.s1.hs->random[i] = rand();
	}
    
    if ([Util writeAll:stream buf:self.s1.hs len:sizeof(HandshakeStruct)] < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: sendS1 error!\n");
        exit(-1);
    }
}

- (void)recvC1:(Stream*)stream {
    self.c1 = [[Handshake alloc] init];
        
    size_t n;
    if ((n = [Util readAll:stream buf:self.c1.hs len:sizeof(HandshakeStruct)]) < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: recvC1 error(Unexpected EOF while reading C1, expected %ld bytes, but only read %ld bytes)!\n", sizeof(HandshakeStruct), n);
        exit(-1);
    }
}

- (void)sendS2:(Stream*)stream {
    if ([Util writeAll:stream buf:self.c1.hs len:sizeof(HandshakeStruct)] < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: sendS2 error!\n");
        exit(-1);
    }
}

- (void)recvC2:(Stream*)stream {
    Handshake *c2 = [[Handshake alloc] init];
    
    size_t n;
    if ((n = [Util readAll:stream buf:c2.hs len:sizeof(HandshakeStruct)]) < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: recvC2 error(Unexpected EOF while reading C2, expected %ld bytes, but only read %ld bytes)!\n", sizeof(HandshakeStruct), n);
        exit(-1);
    }
    
    if (memcmp(self.s1.hs->random, c2.hs->random, RANDOM_LEN) != 0) {
		NSLog(@"invalid handshake\n");
        exit(-1);
	}
}

- (void)handshake:(Stream*)stream {
    [self recvC0:stream];
    [self sendS0:stream];
    [self sendS1:stream];
    [self recvC1:stream];
    [self sendS2:stream];
    [self recvC2:stream];
    
    NSLog(@"============server handshake success!============\n");
}

@end
