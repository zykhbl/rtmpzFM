//
//  PCMToAAC.h
//  zFM
//
//  Created by zykhbl on 16-10-4.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCMToAAC : NSObject

- (void)createConverter;
- (NSMutableData*)convertPCMToAAC:(void*)inInputData numberBytes:(UInt32)inNumberBytes;

@end
