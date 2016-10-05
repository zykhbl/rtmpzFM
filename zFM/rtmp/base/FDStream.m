//
//  FDStream.m
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "FDStream.h"
#include <netinet/in.h>

@implementation FDStream

@synthesize fd;

- (size_t)readAll:(void*)buf len:(size_t)len {
    size_t pos = 0;
    
	while (pos < len) {
		ssize_t bytes = recv(self.fd, (char *) buf + pos, len - pos, 0);
        
		if (bytes < 0) {
			if (errno == EAGAIN || errno == EINTR) {
				continue;
            }
            
			printf("unable to recv: %s", strerror(errno));
		} else {
            if (bytes == 0) {
                break;
            }
            
            pos += bytes;
        }
	}
    
	return pos;
}

- (size_t)writeAll:(void*)buf len:(size_t)len {
	size_t pos = 0;
    
	while (pos < len) {
		ssize_t written = send(self.fd, (const char *) buf + pos, len - pos, 0);
        
		if (written < 0) {
			if (errno == EAGAIN || errno == EINTR) {
				continue;
            }
            
			printf("unable to send: %s", strerror(errno));
		} else {
            if (written == 0) {
                break;
            }
            
            pos += written;
        }
	}
    
	return pos;
}

@end
