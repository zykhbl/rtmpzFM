//
//  HandshakeS2C.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Handshake.h"
#import "Stream.h"

@interface HandshakeS2C : NSObject

@property (nonatomic, strong) Handshake *c1;
@property (nonatomic, strong) Handshake *s1;

- (void)handshake:(Stream*)stream;

@end
