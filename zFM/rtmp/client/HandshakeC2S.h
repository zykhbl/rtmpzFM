//
//  HandshakeC2S.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Handshake.h"
#import "Stream.h"

@interface HandshakeC2S : NSObject

@property (nonatomic, strong) Handshake *c1;
@property (nonatomic, strong) Handshake *s1;

- (void)handshake:(Stream*)stream;

@end
