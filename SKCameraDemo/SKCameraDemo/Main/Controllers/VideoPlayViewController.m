//
//  VideoPlayViewController.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/24.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "VideoPlayViewController.h"

@import AVFoundation;

@interface VideoPlayViewController ()
@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIButton *cancelButton;
@end

@implementation VideoPlayViewController

- (instancetype)initWithVideoUrl:(NSURL *)url {
    self = [super init];
    if(self) {
        _videoUrl = url;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    self.player = [AVPlayer playerWithURL:self.videoUrl];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.player currentItem]];
    
    
    self.playerLayer.frame = CGRectMake(0, 0, DeviceWidth, DeviceHeight);
    [self.view.layer addSublayer:self.playerLayer];
    
    [self.view addSubview:self.cancelButton];
    [self.player play];

   
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.player play];

}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


-(UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.frame = CGRectMake(0, 0, 40, 40);
        _cancelButton.tintColor = [UIColor whiteColor];
        [_cancelButton setImage:[UIImage imageNamed:@"off_"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (void)cancelButtonPressed:(UIButton *)button {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
