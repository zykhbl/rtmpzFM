//
//  AmfNull.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmfData.h"

@interface AmfNull : AmfData

+ (void)writeNullTo:(Stream*)outStream;

@end
