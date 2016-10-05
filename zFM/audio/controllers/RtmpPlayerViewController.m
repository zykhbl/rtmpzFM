//
//  RtmpPlayerViewController.m
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpPlayerViewController.h"
#import "MyTool.h"

@implementation RtmpPlayerViewController

@synthesize player;
@synthesize rtmpPlayer;
@synthesize aacData;
@synthesize count;
@synthesize flag;

- (IBAction)listen:(id)sender {
    UIButton *playBtn = (UIButton*)sender;
    playBtn.enabled = NO;
    [playBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    self.rtmpPlayer = [[RtmpPlayer alloc] init];
    self.rtmpPlayer.delegate = self;
    [self.rtmpPlayer connect:IPADDR];
    [self.rtmpPlayer startDoPollThread];
    
    self.aacData = [[NSMutableData alloc] init];
    self.count = 0;
    self.flag = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake((320.0 - 40.0) * 0.5, 50.0, 40.0, 40.0);
    [playBtn setTitle:@"收听" forState:UIControlStateNormal];
    [playBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(listen:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
}

//============RtmpConnectionDelegate============
- (void)RtmpConnection:(RtmpConnection*)connection play:(Float64)mSampleRate mBitsPerChannel:(UInt32)mBitsPerChannel {
    self.player = [[AACPlayer alloc] init];
    [self.player openAudio];
}

- (void)RtmpConnection:(RtmpConnection*)connection addAudioBuf:(const void*)inInputData numberBytes:(UInt32)inNumberBytes {
    NSMutableData *audioData = [[NSMutableData alloc] init];
    NSData *adtsData = [self.player adtsDataForPacketLength:inNumberBytes];
    [audioData appendData:adtsData];
    [audioData appendBytes:inInputData length:inNumberBytes];
    
    if (self.flag) {
        [self.aacData appendData:audioData];
        self.count++;
        
        if (self.count % 20 == 0) {
            [self.player playAudio:(char*)self.aacData.bytes len:self.aacData.length];
            self.aacData = [[NSMutableData alloc] init];
            self.count = 0;
            self.flag = NO;
        }
    } else {
        [self.player playAudio:(char*)audioData.bytes len:audioData.length];
    }
}

@end
