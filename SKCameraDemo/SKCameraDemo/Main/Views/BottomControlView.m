//
//  BottomControlView.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "BottomControlView.h"
#import "SKCamera.h"

@interface BottomControlView ()

@property (strong, nonatomic) UIButton *slectPhotoButton;

@property (strong, nonatomic) UIButton *switchButton;

@end

@implementation BottomControlView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        [self setSubviews];
    }
    return self;
}


- (void)setSubviews {
    // 1. 高斯模糊
    UIBlurEffect *beffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:beffect];
    view.frame = self.bounds;
    [self addSubview:view];
    
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsZero);
    }];
    
    // 2. recordCircleView
    [self addSubview:self.recordCircleView];
    [self.recordCircleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kscaleDeviceWidth(360));
        make.bottom.equalTo(self.mas_bottom).offset(-20);
        make.centerX.equalTo(self.mas_centerX);
    }];
    
    // 3. slectPhotoButton
    [self addSubview:self.slectPhotoButton];
    [self.slectPhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.left.equalTo(self.mas_left).offset(kscaleDeviceWidth(180));
        make.centerY.equalTo(self.recordCircleView.mas_centerY);
    }];
    
    if([SKCamera isFrontCameraAvailable] && [SKCamera isRearCameraAvailable]) {
       
        // 3. switch button
        [self addSubview:self.switchButton];
        [self.switchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(40);
            make.right.equalTo(self.mas_right).offset( - kscaleDeviceWidth(180));
            make.centerY.equalTo(self.recordCircleView.mas_centerY);
        }];
    }
}


- (void)switchButtonPressed:(UIButton *)button
{
    if (self.switchButtonPressed) {
        self.switchButtonPressed(button);
    }
}


- (void)slectPhotoButtonPressed:(UIButton *)button
{
    if (self.slectPhotoButtonPressed) {
        self.slectPhotoButtonPressed(button);
    }
}


- (CircleProgressView *)recordCircleView {

    if (!_recordCircleView) {
        _recordCircleView = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, kscaleDeviceWidth(360), kscaleDeviceWidth(360))];
    }
    return _recordCircleView;
}


- (UIButton *)switchButton {
    
    if (!_switchButton) {
        _switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _switchButton.frame = CGRectZero;
        _switchButton.tintColor = [UIColor whiteColor];
        [_switchButton setImage:[UIImage imageNamed:@"rear_camera_"] forState:UIControlStateNormal];
        [_switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _switchButton;
}


- (UIButton *)slectPhotoButton {
    
    if (!_slectPhotoButton) {
        _slectPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _slectPhotoButton.frame = CGRectZero;
        _slectPhotoButton.tintColor = [UIColor whiteColor];
        [_slectPhotoButton setImage:[UIImage imageNamed:@"import_"] forState:UIControlStateNormal];
        [_slectPhotoButton addTarget:self action:@selector(slectPhotoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _slectPhotoButton;
}


- (void)layoutSubviews {
    
    [super layoutSubviews];
}


@end
