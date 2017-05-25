//
//  UIButton+PreventMultipleClicks.h
//  FaceCall
//
//  Created by KUN on 16/11/28.
//  Copyright © 2016年 AiYan. All rights reserved.
//

#import <UIKit/UIKit.h>

#define defaultClicktimerInterval  .5  //默认间隔时间

@interface UIButton (PreventMultipleClicks)

/** 点击时间间隔*/
@property (nonatomic , assign) NSTimeInterval clicktimerInterval;

/** 是否需要防止多次点击*/
@property (nonatomic , assign) BOOL isNeedPrevent;

@end
