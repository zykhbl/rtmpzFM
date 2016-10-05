//
//  RtmpPublisherViewController.m
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpPublisherViewController.h"

@implementation RtmpPublisherViewController

@synthesize player;
@synthesize publisher;
@synthesize pcmToAac;

- (IBAction)publish:(id)sender {
    UIButton *publishBtn = (UIButton*)sender;
    publishBtn.enabled = NO;
    [publishBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    self.publisher = [[RtmpPublisher alloc] init];
    self.publisher.delegate = self;
    [self.publisher connect:IPADDR];
    [self.publisher startDoPollThread];
    
    self.pcmToAac = [[PCMToAAC alloc] init];
    [self.pcmToAac createConverter];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    UIButton *publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    publishBtn.frame = CGRectMake((320.0 - 40.0) * 0.5, 50.0, 40.0, 40.0);
    [publishBtn setTitle:@"推流" forState:UIControlStateNormal];
    [publishBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [publishBtn addTarget:self action:@selector(publish:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:publishBtn];
}

//============AQPlayerDelegate============
- (void)AQPlayer:(AQPlayer*)player publishAudioBuf:(const void*)inInputData numberBytes:(UInt32)inNumberBytes {
    NSMutableData *audioData = [self.pcmToAac convertPCMToAAC:(void*)inInputData numberBytes:inNumberBytes];
    [self.publisher publishAudioData:audioData dts:0];
    
    NSLog(@"========publishAudioBuf========");
}

//============RtmpConnectionDelegate============
- (void)RtmpConnection:(RtmpConnection*)connection beginStream:(BOOL)flag {
    self.player = [[AQPlayer alloc] init];
    self.player.delegate = self;
    [self.player play:@"file://qingyuyi.mp3"];
}

@end
