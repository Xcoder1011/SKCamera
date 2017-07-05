//
//  CALayer+ControlAnimation.h
//  SKCameraDemo
//
//  Created by KUN on 17/7/5.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (ControlAnimation)


/**
 * 暂停layer上的动画
 */
- (void)pauseLayerCoreAnimation;


/**
 * 恢复layer上的动画
 */
- (void)resumeLayerCoreAnimation;

@end
