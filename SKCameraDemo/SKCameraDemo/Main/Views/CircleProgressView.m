//
//  CircleProgressView.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "CircleProgressView.h"

@interface CircleProgressView ()

@property (nonatomic, strong) CALayer *middleLayer;
@property (nonatomic, strong) CALayer *bgLayer;

@property (nonatomic, strong) UIButton *tapButton;

@end

static float const ANIMATION_DURATION = 0.5; // duration

static inline CABasicAnimation* ScaleAnimation(CGFloat fromValue, CGFloat toValue,float duration) {
    
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    anima.fromValue = [NSNumber numberWithFloat:fromValue];
    anima.toValue = [NSNumber numberWithFloat:toValue];
    anima.duration = duration;
    anima.fillMode = kCAFillModeForwards;
    anima.removedOnCompletion = NO;
    return anima;
    
}

@implementation CircleProgressView

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self setSubLayers];
    }
    return self;
}

- (void)setSubLayers {
    
    [self.layer addSublayer:self.bgLayer];
    [self.layer addSublayer:self.middleLayer];
    
    [self addSubview:self.tapButton];
    [self.tapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kscaleDeviceWidth(150));
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
    }];
}


- (void)tapButtonPressed:(UIButton *)btn {
    
    btn.selected = !btn.selected;
    
    if (btn.selected) {
        
        [self.middleLayer addAnimation:ScaleAnimation(1.0, 12.0/15, ANIMATION_DURATION) forKey:@"middlelayer"];
        
        [self.bgLayer addAnimation:ScaleAnimation(1.0, 36.0/24, ANIMATION_DURATION) forKey:@"bgLayer"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (self.startRecordingVideo) {
                self.startRecordingVideo(btn);
            }
        });
       
    } else {
        if (self.stopRecordingVideo) {
            self.stopRecordingVideo(btn);
        }
    }
    
}


- (CALayer *)bgLayer {

    if (!_bgLayer) {
        _bgLayer = [CALayer layer];
        _bgLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
        _bgLayer.bounds = CGRectMake(0, 0, kscaleDeviceWidth(240), kscaleDeviceWidth(240));
        _bgLayer.position = self.center;
        _bgLayer.cornerRadius = kscaleDeviceWidth(240) / 2.0;
        
    }
    return _bgLayer;
}

- (CALayer *)middleLayer {
    
    if (!_middleLayer) {
        _middleLayer = [CALayer layer];
        _middleLayer.backgroundColor = [UIColor whiteColor].CGColor;
        _middleLayer.bounds = CGRectMake(0, 0, kscaleDeviceWidth(150), kscaleDeviceWidth(150));
        _middleLayer.position = self.center;
        _middleLayer.cornerRadius = kscaleDeviceWidth(150) / 2.0;
        
    }
    return _middleLayer;
}

- (UIButton *)tapButton {

    if (!_tapButton) {
        _tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _tapButton.frame = CGRectZero;
        _tapButton.tintColor = [UIColor clearColor];
        [_tapButton addTarget:self action:@selector(tapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _tapButton;
}




@end
