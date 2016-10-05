//
//  PollManager.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "PollManager.h"

@implementation PollManager

@synthesize pollSize;
@synthesize capacity;
@synthesize poll_table;
@synthesize clients;

- (void)dealloc {
    if (self.poll_table != NULL) {
        free(self.poll_table);
    }
    
    if (self.clients != NULL) {
        for (int i = 0; i < self.capacity; ++i) {
            Client *client = (__bridge_transfer Client *)(self.clients[i]);
            if (client != NULL && client.stream.fd > 0) {
                close(client.stream.fd);
            }
            
        }
        
        free(self.clients);
    }
}

- (id)initWithCapacity:(int)c {
    self = [super init];
    
    if (self) {
        self.pollSize = 0;
        self.capacity = c;
        int poll_table_size = sizeof(struct pollfd) * self.capacity;
        self.poll_table = (struct pollfd *)malloc(poll_table_size);
        memset(self.poll_table, 0, poll_table_size);
        
        int clients_size = sizeof(Client*) * self.capacity;
        self.clients = (void**)malloc(clients_size);
        memset(self.clients, 0, clients_size);
    }
    
    return self;
}

- (void)addPollInfo:(int)fd events:(short)events flag:(BOOL)flag {
    for (int i = 0; i < self.capacity; ++i) {
        if (self.poll_table[i].fd == 0) {
            self.poll_table[i].events = events;
            self.poll_table[i].revents = 0;
            self.poll_table[i].fd = fd;
            
            if (flag) {
                Client *c = [[Client alloc] init];
                c.stream.fd = fd;
                self.clients[i] = (__bridge_retained void *)(c);
            } else {
                self.clients[i] = NULL;
            }
            
            self.pollSize++;
            return;
        }
    }
    
    NSLog(@"poll_table is full");
}

- (void)addPollClient:(Client*)c {
    for (int i = 0; i < self.capacity; ++i) {
        if (self.poll_table[i].fd == 0) {
            self.poll_table[i].events = POLLIN | POLLOUT;
            self.poll_table[i].revents = 0;
            self.poll_table[i].fd = c.stream.fd;
            
            self.clients[i] = (__bridge_retained void *)(c);
            
            self.pollSize++;
            return;
        }
    }
    
    NSLog(@"poll_table is full");
}

- (void)deletePollInfo {
    
}

@end
