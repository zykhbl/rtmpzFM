//
//  RtmpServerViewController.m
//  zFM
//
//  Created by zykhbl on 16-10-3.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "RtmpServerViewController.h"

@implementation RtmpServerViewController

@synthesize server;

- (IBAction)startServer:(id)sender {
    UIButton *startServerBtn = (UIButton*)sender;
    startServerBtn.enabled = NO;
    [startServerBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    self.server = [[RtmpServer alloc] init];
    [self.server listen];
    [self.server startDoPollThread];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    UIButton *startServerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    startServerBtn.frame = CGRectMake((320.0 - 100.0) * 0.5, 50.0, 100.0, 40.0);
    [startServerBtn setTitle:@"启动服务器" forState:UIControlStateNormal];
    [startServerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [startServerBtn addTarget:self action:@selector(startServer:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startServerBtn];
}

@end
