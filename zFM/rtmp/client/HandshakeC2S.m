//
//  HandshakeC2S.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "HandshakeC2S.h"
#import "Util.h"

@implementation HandshakeC2S

@synthesize c1;
@synthesize s1;

- (void)sendC0:(Stream*)stream {
    int8_t c0 = (int8_t)PROTOCOL_VERSION;
    
    if ([Util writeAll:stream buf:&c0 len:1] < 1) {
        NSLog(@"handshake: sendC0 error!\n");
        exit(-1);
    }
}

- (void)sendC1:(Stream*)stream {
    self.c1 = [[Handshake alloc] init];
	self.c1.hs->time[0] = (int8_t)PROTOCOL_VERSION;  //??为什么不是0
    
	for (int i = 0; i < RANDOM_LEN; ++i) {
		self.c1.hs->random[i] = rand();
	}
    
    if ([Util writeAll:stream buf:self.c1.hs len:sizeof(HandshakeStruct)] < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: sendC1 error!\n");
        exit(-1);
    }
}

- (void)recvS0:(Stream*)stream {
    int8_t s0 = 0;
    
    if ([Util readAll:stream buf:&s0 len:1] < 1) {
        NSLog(@"handshake: recvS0 error!\n");
        exit(-1);
    }
    
    if (s0 != PROTOCOL_VERSION) {
        if (s0 == -1) {
            NSLog(@"handshake: recvS0 error(InputStream closed)!\n");
        } else {
            NSLog(@"handshake: recvS0 error(Invalid RTMP protocol version; expected %d, got %d)!\n", PROTOCOL_VERSION, s0);
        }
        
        exit(-1);
    }
}

- (void)recvS1:(Stream*)stream {
    self.s1 = [[Handshake alloc] init];
    
    size_t n;
    if ((n = [Util readAll:stream buf:self.s1.hs len:sizeof(HandshakeStruct)]) < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: recvS1 error(Unexpected EOF while reading S1, expected %ld bytes, but only read %ld bytes)!\n", sizeof(HandshakeStruct), n);
        exit(-1);
    }
}

- (void)sendC2:(Stream*)stream {
    if ([Util writeAll:stream buf:self.s1.hs len:sizeof(HandshakeStruct)] < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: sendC2 error!\n");
        exit(-1);
    }
}

- (void)recvS2:(Stream*)stream {
    Handshake *s2 = [[Handshake alloc] init];
    
    size_t n;
    if ((n = [Util readAll:stream buf:s2.hs len:sizeof(HandshakeStruct)]) < sizeof(HandshakeStruct)) {
        NSLog(@"handshake: recvS2 error(Unexpected EOF while reading S2, expected %ld bytes, but only read %ld bytes)!\n", sizeof(HandshakeStruct), n);
        exit(-1);
    }
    
    if (memcmp(self.c1.hs->random, s2.hs->random, RANDOM_LEN) != 0) {
		NSLog(@"invalid handshake\n");
        exit(-1);
	}
}

- (void)handshake:(Stream*)stream {
    [self sendC0:stream];
    [self sendC1:stream];
    [self recvS0:stream];
    [self recvS1:stream];
    [self sendC2:stream];
    [self recvS2:stream];
    
    NSLog(@"============client handshake success!============\n");
}

@end
