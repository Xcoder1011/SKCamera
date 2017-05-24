//
//  CircleProgressView.h
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleProgressView : UIView

@property (nonatomic , copy) void (^startRecordingVideo)( UIButton * btn);

@property (nonatomic , copy) void (^stopRecordingVideo)( UIButton * btn);

@end
