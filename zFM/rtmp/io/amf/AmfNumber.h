//
//  AmfNumber.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmfData.h"

#define AMFNUMBERSIZE    9

@interface AmfNumber : AmfData

@property (nonatomic, assign) double value;

- (id)initWithValue:(double)v;

+ (double)readNumberFrom:(Stream*)inStream;
+ (void)writeNumberTo:(Stream*)outStream number:(double)number;

@end
