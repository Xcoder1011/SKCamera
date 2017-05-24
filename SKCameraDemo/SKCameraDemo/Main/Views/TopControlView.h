//
//  TopControlView.h
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TopControlView : UIView

// 闪光灯
@property (strong, nonatomic) UIButton *flashButton;

@property (nonatomic , copy) void (^flashButtonPressed)( UIButton * btn);


@end
