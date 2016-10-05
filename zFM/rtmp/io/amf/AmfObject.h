//
//  AmfObject.h
//  zFM
//
//  Created by zykhbl on 16-9-24.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmfData.h"

@interface AmfObject : AmfData

@property (nonatomic, strong) NSMutableDictionary *properties;
@property (nonatomic, assign) int size;

- (AmfData*)getProperty:(NSString*)key;
- (void)setProperty:(NSString*)key amfData:(AmfData*)amfData;
- (void)setProperty:(NSString*)key boolean:(BOOL)bl;
- (void)setProperty:(NSString*)key string:(NSString*)str;
- (void)setProperty:(NSString*)key numberInt:(int)intV;
- (void)setProperty:(NSString*)key numberDouble:(double)doubleV;

@end
