//
//  RtmpNetwork.m
//  zFM
//
//  Created by zykhbl on 16-9-28.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpNetwork.h"
#import "Audio.h"
#import "Video.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation RtmpNetwork

@synthesize pm;
@synthesize logPrevStr;

- (void)handshake {
    
}

- (void)sendRtmpPacket:(RtmpPacket*)rtmpPacket toClient:(Client*)client {
    ChunkStreamInfo *chunkStreamInfo = [client.rtmpSessionInfo getChunkStreamInfo:rtmpPacket.header.chunkStreamId];
    chunkStreamInfo.prevHeaderTx = rtmpPacket.header;
    
    if (!([rtmpPacket isKindOfClass:[Audio class]] || [rtmpPacket isKindOfClass:[Video class]])) {
        rtmpPacket.header.absoluteTimestamp = [chunkStreamInfo markAbsoluteTimestampTx];
    }
    
    BytesStream *baos = [[BytesStream alloc] init];
    [rtmpPacket writeBody:baos];
    
    rtmpPacket.header.packetLength = [baos length];
    int remainingBytes = [baos length];
    
    BytesStream *chunkStream = [[BytesStream alloc] init];
    
    // Write header for chunk
    [rtmpPacket.header writeTo:chunkStream chunkType:TYPE_0_FULL chunkStreamInfo:chunkStreamInfo];
    
    size_t n = 0;
    while (remainingBytes > client.rtmpSessionInfo.txChunkSize) {
        // Write packet for chunk
        n = [Util writeAll:chunkStream buf:(char*)baos.data.bytes + baos.readOffset len:client.rtmpSessionInfo.txChunkSize];
        
        [client lock];
        [client.sendQueue addObject:chunkStream];
        [client unlock];
        
        remainingBytes -= n;
        baos.readOffset += n;
        
        chunkStream = [[BytesStream alloc] init];
        // Write header for remain chunk
        [rtmpPacket.header writeTo:chunkStream chunkType:TYPE_3_RELATIVE_SINGLE_BYTE chunkStreamInfo:chunkStreamInfo];
    }
    n = [Util writeAll:chunkStream buf:(char*)baos.data.bytes + baos.readOffset len:remainingBytes];
    baos.readOffset += n;
    
    [client lock];
    [client.sendQueue addObject:chunkStream];
    [client unlock];
    
    NSLog(@"%@ wrote packet: %@, size: %d", self.logPrevStr, rtmpPacket, rtmpPacket.header.packetLength);
    
    if ([rtmpPacket isKindOfClass:[Command class]]) {
        [client.rtmpSessionInfo addInvokedCommand:[(Command*)rtmpPacket transactionId] commandName:[(Command*)rtmpPacket commandName]];
    }
}

- (void)handleRxRtmpPacket:(RtmpPacket*)rtmpPacket toClient:(Client*)client {
    
}

- (void)handleRxPacket:(Client*)client {// Handle all queued received RTMP packets
    while ([client.recvStream length] > 0) {
        RtmpPacket *rtmpPacket = [client.rtmpDecoder readPacket:client.recvStream];
        
        if (rtmpPacket == nil) {// It will be blocked when no data in input stream buffer
            return;
        }
        
        [client.recvStream afterDecodedRtmpPacket];
        
        [self handleRxRtmpPacket:rtmpPacket toClient:client];
    }
}

- (void)doPoll {
    for (size_t i = 0; i < self.pm.pollSize; ++i) {
        Client *client = (__bridge Client *)(self.pm.clients[i]);
		if (client != NULL && client.stream.fd > 0) {
            [client lock];
			if (client.sendQueue.count > 0) {
//				NSLog(@"%@ waiting for pollout", self.logPrevStr);
				self.pm.poll_table[i].events = POLLIN | POLLOUT;
			} else {
				self.pm.poll_table[i].events = POLLIN;
			}
            [client unlock];
		}
	}
    
    if (poll(self.pm.poll_table, self.pm.pollSize, 60) < 0) {
        if (errno == EAGAIN || errno == EINTR) {
            return;
        }
        NSLog(@"%@ poll() failed: %s", self.logPrevStr, strerror(errno));
    }
    
    for (size_t i = 0; i < self.pm.pollSize; ++i) {
        if (self.pm.poll_table[i].fd != 0) {
            Client *client = (__bridge Client *)(self.pm.clients[i]);
            if (self.pm.poll_table[i].revents & POLLOUT) {
                [client lock];
                if ([client.sendQueue count] > 0) {
                    BytesStream *bytesStream = [client.sendQueue firstObject];
                    
                    size_t len = [bytesStream length];
                    ssize_t written = send(client.stream.fd, (char*)bytesStream.data.bytes + bytesStream.readOffset, sizeof(char) * len, 0);
                    if (written < 0) {
                        if (errno == EAGAIN || errno == EINTR) {

                        }
                        NSLog(@"%@ unable to write: %s", self.logPrevStr, strerror(errno));
//                        exit(-1);//正确的方式应该关闭当前Client
                    } else if (written > 0) {
                        bytesStream.readOffset += written;
                        
                        if (written == len) {
                            [client.sendQueue removeObjectAtIndex:0];
                            NSLog(@"%@ send: %ld bytes", self.logPrevStr, written);
                        } else {
                            NSLog(@"%@ send not all bytesStream length: %ld bytes", self.logPrevStr, written);
                        }
                    }
                }
                [client unlock];
            }
            
            if (self.pm.poll_table[i].revents & POLLIN) {
                if (client == NULL) {
                    [self handshake];
                } else {
                    char buf[BUFSIZE] = {0};
                    ssize_t got = recv(client.stream.fd, &buf, sizeof(char) * BUFSIZE, 0);
                    if (got == 0) {
//                            NSLog(@"%@, EOF from a Client", self.logPrevStr);
                        continue;
                    } else if (got < 0) {
                        if (errno == EAGAIN || errno == EINTR) {
                            continue;
                        }
                        NSLog(@"%@ unable to read: %s", self.logPrevStr, strerror(errno));
                        exit(-1);//正确的方式应该关闭当前Client
                    } else {
                        [client.recvStream writeAll:buf len:got];
                        NSLog(@"%@ recv: %ld bytes", self.logPrevStr, got);
                        
                        [self handleRxPacket:client];
                    }
                }
            }
        }
    }
}

- (void)startDoPollThread {
    __weak typeof(self) weak_self = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
            [weak_self doPoll];
        }
    });
}

@end
