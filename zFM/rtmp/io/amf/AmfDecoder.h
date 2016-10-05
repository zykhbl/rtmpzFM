//
//  AmfDecoder.h
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmfData.h"

@interface AmfDecoder : NSObject

+ (AmfData*)readFrom:(Stream*)inStream;

@end
