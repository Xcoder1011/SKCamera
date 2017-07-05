//
//  BottomControlView.h
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleProgressView.h"

@interface BottomControlView : UIView

@property (strong, nonatomic) CircleProgressView *recordCircleView;

@property (nonatomic , copy) void (^switchButtonPressed)( UIButton * btn);

@property (nonatomic , copy) void (^doneButtonPressed)( UIButton * btn);

@end
