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

@property (strong, nonatomic) UIButton *doneButton;

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
    [self addSubview:self.doneButton];
    [self.doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.right.equalTo(self.mas_right).offset( - kscaleDeviceWidth(180));
        make.centerY.equalTo(self.recordCircleView.mas_centerY);
    }];
    
    
    if([SKCamera isFrontCameraAvailable] && [SKCamera isRearCameraAvailable]) {
        // 3. switch button
        [self addSubview:self.switchButton];
        [self.switchButton mas_makeConstraints:^(MASConstraintMaker *make) {
           
            make.width.height.mas_equalTo(40);
            make.left.equalTo(self.mas_left).offset(kscaleDeviceWidth(180));
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



- (CircleProgressView *)recordCircleView {

    if (!_recordCircleView) {
        _recordCircleView = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, kscaleDeviceWidth(360), kscaleDeviceWidth(360))];
        _recordCircleView.progressLineColor = [UIColor whiteColor];
        _recordCircleView.totalTime = 15;
    }
    return _recordCircleView;
}


- (UIButton *)switchButton {
    
    if (!_switchButton) {
        
        __weak typeof(self) weakself = self;

        UIButton *switchBtn = [SKButton buttonWith:^(SKButton *btn) {
            
            btn.
            
            frame_(CGRectZero).
            
            imageName_(@"rear_camera_").
            
            target_and_Action_(weakself, @selector(switchButtonPressed:));
            
        }];
        
        _switchButton = switchBtn ;

    }
    return _switchButton;
}


- (UIButton *)doneButton {
    
    if (!_doneButton) {
        
        __weak typeof(self) weakself = self;
        
        UIButton *doneBtn = [SKButton createImgButtonWithFrame:CGRectZero imageName:@"done_" clickAction:^(UIButton *btn) {
            if (weakself.doneButtonPressed) {
                weakself.doneButtonPressed(btn);
            }
        }];
        _doneButton = doneBtn;
    }
    return _doneButton;
}


- (void)layoutSubviews {
    
    [super layoutSubviews];
}


@end
