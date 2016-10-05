//
//  AACToPCM.h
//  zFM
//
//  Created by zykhbl on 16-10-4.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AACToPCM : NSObject

- (void)createConverter;
- (NSMutableData*)convertAACToPCM:(void*)inInputData numberBytes:(UInt32)inNumberBytes;
- (NSData*)adtsDataForPacketLength:(NSUInteger)packetLength;

@end
