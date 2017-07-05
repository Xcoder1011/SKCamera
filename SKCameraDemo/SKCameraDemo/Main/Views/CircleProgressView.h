//
//  CircleProgressView.h
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleProgressView : UIView

@property (assign, nonatomic) CGFloat progressLineWidth;

@property (strong, nonatomic) UIColor * progressLineColor;

@property (strong, nonatomic) UIColor * timerLabelColor;

@property (assign, nonatomic) NSInteger totalTime;

@property (assign, nonatomic) CGFloat startAngle;

@property (assign, nonatomic) CGFloat endAngle;

@property (nonatomic , copy) void (^clickRecordingBlock)( UIButton * btn);

@property (nonatomic , copy) void (^stopRecordingVideo)( UIButton * btn);

- (void)reset ;

@end
