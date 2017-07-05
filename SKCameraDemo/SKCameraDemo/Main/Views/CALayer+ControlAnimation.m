//
//  CALayer+ControlAnimation.m
//  SKCameraDemo
//
//  Created by KUN on 17/7/5.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "CALayer+ControlAnimation.h"

@implementation CALayer (ControlAnimation)

// 暂停layer上的动画
- (void)pauseLayerCoreAnimation {
    
    dispatch_async_on_main_queue(^{
        // 将当前时间CACurrentMediaTime转换为layer上的时间, 即将parent time转换为localtime
        CFTimeInterval pausedTime = [self convertTime:CACurrentMediaTime() fromLayer:nil];
        // localtime与parenttime的比例为0, 意味着localtime暂停了
        self.speed = 0.0;
         // 设置layer的timeOffset, 在继续操作也会使用到
        self.timeOffset = pausedTime;
        
    });
  }


// 恢复layer上的动画
- (void)resumeLayerCoreAnimation {
    
    dispatch_async_on_main_queue(^{
       
        CFTimeInterval pausedTime = [self timeOffset];
        
        // 1. 让CALayer的时间继续行走
        self.speed = 1.0;
        // 2. 取消上次记录的停留时刻
        self.timeOffset = 0.0;
        // 3. 取消上次设置的时间
        self.beginTime = 0.0;
        
        // 4. 计算暂停的时间(这里也可以用CACurrentMediaTime()-pausedTime)
        CFTimeInterval timeSincePause = [self convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        // 5. 设置相对于父坐标系的开始时间(往后退timeSincePause)
        self.beginTime = timeSincePause;

    });
}



@end
