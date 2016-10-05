//
//  AmfDecoder.m
//  zFM
//
//  Created by zykhbl on 16-9-23.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "AmfDecoder.h"
#import "AmfString.h"
#import "AmfNull.h"
#import "AmfBoolean.h"
#import "AmfNumber.h"
#import "AmfObject.h"
#import "AmfArray.h"
#import "AmfMap.h"
#import "AmfUndefined.h"
#import "Util.h"

@implementation AmfDecoder

+ (AmfData*)readFrom:(Stream*)inStream {
    AmfData *amfData = nil;
    
    char amfType = [Util readUnsignedChar:inStream];
    switch (amfType) {
        case NUMBER:
            amfData = [[AmfNumber alloc] init];
            break;
        case BOOLEAN:
            amfData = [[AmfBoolean alloc] init];
            break;
        case STRING:
            amfData = [[AmfString alloc] init];
            break;
        case OBJECT:
            amfData = [[AmfObject alloc] init];
            break;
        case NULLL:
            return [[AmfNull alloc] init];
        case UNDEFINED:
            return [[AmfUndefined alloc] init];
        case MAP:
            amfData = [[AmfMap alloc] init];
            break;
        case ARRAY:
            amfData = [[AmfArray alloc] init];
            break;
        default:
            NSLog(@"Unknown/unimplemented AMF data type: %c", amfType);
    }
    
    [amfData readFrom:inStream];
    return amfData;
}

@end
