//
//  AmfData.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stream.h"

#define NUMBER      0x00
#define BOOLEAN     0x01
#define STRING      0x02
#define OBJECT      0x03
#define NULLL       0x05
#define UNDEFINED   0x06
#define MAP         0x08
#define ARRAY       0x0A

@interface AmfData : NSObject

- (void)writeTo:(Stream*)inStream;
- (void)readFrom:(Stream*)outStream;
- (int)getSize;

@end
