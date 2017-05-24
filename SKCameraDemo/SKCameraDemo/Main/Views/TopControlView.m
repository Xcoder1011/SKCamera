//
//  TopControlView.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "TopControlView.h"

@interface TopControlView ()

@end

@implementation TopControlView

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
    
    // 2. flash button
    [self addSubview:self.flashButton];
    [self.flashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.top.equalTo(self.mas_top).offset(20);
        make.left.equalTo(self.mas_left).offset(20);
    }];
}


- (void)flashButtonPressed:(UIButton *)button
{
    if (self.flashButtonPressed) {
        self.flashButtonPressed(button);
    }
}


-(UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashButton.frame = CGRectZero;
        _flashButton.tintColor = [UIColor whiteColor];
        [_flashButton setImage:[UIImage imageNamed:@"flash_auto_"] forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
}

@end
