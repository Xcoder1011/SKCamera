//
//  VideoPlayViewController.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/24.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "VideoPlayViewController.h"
#import "SKCamera+Helper.h"

@import AVFoundation;
@import Photos;

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
    [self setBottomControlView];
}

-(void)setBottomControlView {
    
    UIView *bottomControlView = [UIView new];
//    UIBlurEffect *beffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:beffect];
//    [bottomControlView addSubview:effectView];
    
    kWeakObj(self)

    // 1. doneBtn
    UIButton *doneBtn = [SKButton createImgButtonWithFrame:CGRectZero imageName:@"done_" clickAction:^(UIButton *btn) {
        NSLog(@"OK");
    }];
    
    // 2. backBtn
    UIButton *backBtn = [SKButton createImgButtonWithFrame:CGRectZero imageName:@"back_" clickAction:^(UIButton *btn) {
        [weakself.navigationController popViewControllerAnimated:YES];
    }];
    
    // 3. saveBtn
    UIButton *saveBtn = [SKButton createImgButtonWithFrame:CGRectZero imageName:@"save_" clickAction:^(UIButton *btn) {
        NSLog(@"save to album");
        
        [SVProgressHUD showWithStatus:@"视频处理中..."];
        [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeFlat];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:weakself.videoUrl];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                    [SVProgressHUD dismissWithDelay:0.3];
                    
                } else {
                    [SVProgressHUD showErrorWithStatus:@"保存失败"];
                    [SVProgressHUD dismissWithDelay:0.3];
                }
            });
        }];
        
    }];
    
    [bottomControlView addSubview:doneBtn];
    [bottomControlView addSubview:backBtn];
    [bottomControlView addSubview:saveBtn];

    [self.view addSubview:bottomControlView];
    
    [bottomControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.height.mas_equalTo( self.view.height - self.view.width - kscaleDeviceWidth(240));
    }];
    
//    [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(bottomControlView).insets(UIEdgeInsetsZero);
//    }];
    
    [doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kscaleDeviceWidth(360));
        make.bottom.equalTo(self.view.mas_bottom).offset(-20);
        make.centerX.equalTo(self.view.mas_centerX);
    }];
    
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.left.equalTo(self.view.mas_left).offset(kscaleDeviceWidth(180));
        make.centerY.equalTo(doneBtn.mas_centerY);
    }];
    
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.right.equalTo(self.view.mas_right).offset( - kscaleDeviceWidth(180));
        make.centerY.equalTo(doneBtn.mas_centerY);
    }];
}

-(void)setTopControlView {
    
    UIView *topControlView = [UIView new];
//    UIBlurEffect *beffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:beffect];
//    [topControlView addSubview:effectView];
    

    // 1. dismissBtn
    
    UIButton *dismissBtn = [SKButton buttonWith:^(SKButton *btn) {
        
        btn.
        
        frame_(CGRectZero).
        
        imageName_(@"off_").
        
        target_and_Action_(self,@selector(dismissBtnAction));
    }];
    
    
    [topControlView addSubview:dismissBtn];
    [self.view addSubview:topControlView];

    [topControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.height.mas_equalTo(kscaleDeviceWidth(240));
    }];
    
//    [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(topControlView).insets(UIEdgeInsetsZero);
//    }];
    [dismissBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(20);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.height.width.mas_equalTo(40);
    }];
}

- (void)dismissBtnAction {
    
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)dealloc {
    NSLog(@"dealloc");
}

@end
