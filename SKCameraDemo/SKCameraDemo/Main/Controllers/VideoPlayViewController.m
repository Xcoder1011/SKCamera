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

    [self configVideoPlayer];
    [self setTopControlView];
}

-(void)setTopControlView {
    UIView *topControlView = [UIView new];
    UIBlurEffect *beffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:beffect];
    [topControlView addSubview:effectView];
    
    UIButton *dismissBtn = [SKButton createImgButtonWithFrame:CGRectZero imageName:@"off_" clickAction:^(UIButton *btn) {
        NSLog(@"取消录制");
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    [topControlView addSubview:dismissBtn];
    [self.view addSubview:topControlView];
    

    [topControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.height.mas_equalTo(kscaleDeviceWidth(240));
    }];
    
    [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(topControlView).insets(UIEdgeInsetsZero);
    }];
    [dismissBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(20);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.height.width.mas_equalTo(40);
    }];
}



-(void)configVideoPlayer {
    
    self.player = [AVPlayer playerWithURL:self.videoUrl];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.player currentItem]];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.playerLayer];
    [self.view addSubview:self.cancelButton];
    
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

@end
