//
//  RtmpPublisherViewController.h
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQPlayer.h"
#import "RtmpPublisher.h"
#import "PCMToAAC.h"

@interface RtmpPublisherViewController : UIViewController <AQPlayerDelegate, RtmpConnectionDelegate>

@property (nonatomic, strong) AQPlayer *player;
@property (nonatomic, strong) RtmpPublisher *publisher;
@property (nonatomic, strong) PCMToAAC *pcmToAac;

@end
