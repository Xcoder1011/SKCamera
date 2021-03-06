//
//  RecordViewController.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "RecordViewController.h"
#import "SKCamera.h"
#import "SKCamera+Helper.h"
#import "BottomControlView.h"
#import "TopControlView.h"
#import "VideoPlayViewController.h"


@interface RecordViewController ()

@property (strong, nonatomic) SKCamera *camera;

@property (strong, nonatomic) TopControlView *topControlView;

@property (strong, nonatomic) BottomControlView *bottomControlView;

@property (strong, nonatomic) UIView *preView;

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self addSubViews];
    
    [self configCamera];

}

-(void)addSubViews {
    
    _preView = [UIView new];
    _imageView =[UIImageView new];
    
    [self.view addSubview:_preView];
    [self.view addSubview:self.topControlView];
    [self.view addSubview:self.bottomControlView];
    [self.view addSubview:_imageView];
    [self.view bringSubviewToFront:self.imageView];
    
    [self.topControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.height.mas_equalTo(kscaleDeviceWidth(240));
    }];
    
    [self.bottomControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.height.mas_equalTo( self.view.height - self.view.width - kscaleDeviceWidth(240));
    }];
    
    [self.preView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).insets(UIEdgeInsetsZero);
    }];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        
        make.width.mas_equalTo(180);
        make.height.mas_equalTo(180);
    }];
}



-(void)configCamera {

    self.camera = [[SKCamera alloc] initWithVideoQuality:AVCaptureSessionPreset1280x720 position:SKCameraPosition_Back captureDelegate:nil];
    self.camera.previewView = self.preView;
    self.camera.fixOrientationAfterCapture = NO;
    self.camera.needRecord = YES;
    [self.camera prepare];
    
    kWeakObj(self)
    
    [self.camera setDidRecordCompletionBlock:^(SKCamera *camera, NSURL *outputFileUrl, NSError *error) {
        
        VideoPlayViewController *vc = [[VideoPlayViewController alloc] initWithVideoUrl:outputFileUrl];
        [weakself.navigationController pushViewController:vc animated:YES];
    }];
    
    [self.camera setOnDeviceChange:^(SKCamera *camera, AVCaptureDevice * device) {
        
        if([camera isFlashAvailable]) {
            
            weakself.topControlView.flashButton.hidden = NO;
            
            if(camera.flash == SKCameraFlashOff) {
                
               weakself.topControlView.flashButton.selected = NO;
            }
            else {
               weakself.topControlView.flashButton.selected = YES;
            }
        }
        else {
           weakself.topControlView.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnRecordingTimeBlock:^(SKCamera *camera , CGFloat currentRecordTime , CGFloat maxRecordTime) {
        
        [weakself.topControlView.timeLabel setHidden:NO];
        NSString *time = [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(currentRecordTime / 3600.f)) % 100, lround(floor(currentRecordTime/60.f))%60,lround(floor(currentRecordTime/1.f))%60];
        [weakself.topControlView.timeLabel setText:time];
    }];
    
    [self.camera setOnError:^(SKCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:SKCameraErrorDomain]) {
            if(error.code == SKCameraErrorCodeCameraPermission ||
               error.code == SKCameraErrorCodeMicrophonePermission) {
            }
        }
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.topControlView.timeLabel.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.camera sk_shutRecording];
    [self.bottomControlView.recordCircleView reset];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
  
    [self.camera sk_enableRecording];
    [self.bottomControlView.recordCircleView reset];

}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark -- lazy load

-(TopControlView *)topControlView {

    if (!_topControlView) {
        
        _topControlView = [[TopControlView alloc] initWithFrame:CGRectZero];
        
        kWeakObj(self)
        
        // 闪光灯
        _topControlView.flashButtonPressed = ^(UIButton *button) {
        
            if(weakself.camera.flash == SKCameraFlashOff) {
                
                BOOL done = [weakself.camera updateFlashMode:SKCameraFlashOn];
                if(done) {
                    button.selected = YES;
                }
            }
            else {
                BOOL done = [weakself.camera updateFlashMode:SKCameraFlashOff];
                if(done) {
                    button.selected = NO;
                }
            }
            
        };
        
    }
    return _topControlView;
}


- (BottomControlView *)bottomControlView {

    if (!_bottomControlView) {
        
        kWeakObj(self)
        
        _bottomControlView = [[BottomControlView alloc] initWithFrame:CGRectZero];

        _bottomControlView.switchButtonPressed = ^(UIButton *button) {
            NSLog(@"rotate camera");
            [weakself.camera togglePosition];
        };
        
        _bottomControlView.doneButtonPressed = ^(UIButton *button) {
            
            [weakself.camera sk_stopRecording];

        };
        
        _bottomControlView.recordCircleView.clickRecordingBlock = ^(UIButton * button) {
            
            if (button.selected) {
                
                if ([weakself.camera isRecording]) {
                    
                    [weakself.camera sk_resumeRecording];
                } else {
                    
                    /*
                     * if record preview rect use
                     
                    [weakself.camera setupRecordingConfigWithOutputUrl:OutputUrl()
                                                             cropFrame:CGRectZero
                                                         maxRecordTime:15.f] ;
                     */
                    
                    [weakself.camera setupRecordingConfigWithOutputUrl:OutputUrl()
                                                             cropFrame:CGRectMake(0, kscaleDeviceWidth(240), weakself.view.width, weakself.view.width)
                                                         maxRecordTime:15.f] ;
                    
                    [weakself.camera sk_startRecording];
                }
                
            } else {
            
                [weakself.camera sk_pauseRecording];
            }
        };
        
        
        _bottomControlView.recordCircleView.stopRecordingVideo = ^(UIButton *button) {
            
            [weakself.camera sk_stopRecording];

        };
    }
    return _bottomControlView;
}

static inline NSURL * OutputUrl() {

    NSString *tempDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *tempVideoPath= [NSString stringWithFormat:@"%@/SKCameraVideo", tempDocuments];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempVideoPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempVideoPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-DD-HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    NSString *fileName = [NSString stringWithFormat:@"Documents/SKCameraVideo/%@test.mp4",dateTime];
    NSString *pathFirstToMovie = [NSHomeDirectory() stringByAppendingPathComponent:fileName];

    return [NSURL fileURLWithPath:pathFirstToMovie];
}


@end
