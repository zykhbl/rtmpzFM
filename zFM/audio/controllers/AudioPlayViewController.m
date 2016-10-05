//
//  AudioPlayViewController.h
//  zFM
//
//  Created by zykhbl on 15-9-25.
//  Copyright (c) 2015年 zykhbl. All rights reserved.
//

#import "AudioPlayViewController.h"
#import "RtmpServerViewController.h"
#import "RtmpPublisherViewController.h"
#import "RtmpPlayerViewController.h"
#import "PlayerViewController.h"
#import "IpodEQViewController.h"
#import "CustomEQViewController.h"

@implementation AudioPlayViewController

@synthesize rtmpServerVC;
@synthesize rtmpPublisherVC;
@synthesize rtmpPlayerVC;
@synthesize playVC;
@synthesize ipodEQVC;
@synthesize customEQVC;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.rtmpServerVC == nil) {
        self.rtmpServerVC = [[RtmpServerViewController alloc] init];
    }
    
    if (self.rtmpPublisherVC == nil) {
        self.rtmpPublisherVC = [[RtmpPublisherViewController alloc] init];
    }
    
    if (self.rtmpPlayerVC == nil) {
        self.rtmpPlayerVC = [[RtmpPlayerViewController alloc] init];
    }
    
    if (self.playVC == nil) {
        self.playVC = [[PlayerViewController alloc] init];
    }
    
    if (self.ipodEQVC == nil) {
        self.ipodEQVC = [[IpodEQViewController alloc] init];
    }
    
    if (self.customEQVC == nil) {
        self.customEQVC = [[CustomEQViewController alloc] init];
    }
    
    [self addTabScrollView:@[@"服务器", @"电台", @"收音机", @"播放器", @"ipod EQ", @"EQ"] andMainScrollView:@[self.rtmpServerVC, self.rtmpPublisherVC, self.rtmpPlayerVC, self.playVC, self.ipodEQVC, self.customEQVC]];
}

@end
