//
//  AmfString.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmfData.h"

@interface AmfString : AmfData

@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) BOOL key;
@property (nonatomic, assign) int size;

- (id)initWithValue:(NSString*)str key:(BOOL)k;

+ (NSString*)readFrom:(Stream*)inStream key:(BOOL)k;
+ (void)writeStringTo:(Stream*)outStream string:(NSString*)str key:(BOOL)k;
+ (int)sizeOf:(NSString*)str key:(BOOL)k;

@end
