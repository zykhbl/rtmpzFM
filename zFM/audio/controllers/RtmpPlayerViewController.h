//
//  RtmpPlayerViewController.h
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AACPlayer.h"
#import "RtmpPlayer.h"

@interface RtmpPlayerViewController : UIViewController <RtmpConnectionDelegate>

@property (nonatomic, strong) AACPlayer *player;
@property (nonatomic, strong) RtmpPlayer *rtmpPlayer;
@property (nonatomic, strong) NSMutableData *aacData;
@property (nonatomic, assign) int count;
@property (nonatomic, assign) BOOL flag;

@end
