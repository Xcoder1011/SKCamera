//
//  SKOpenGLView.h
//  SKCameraDemo
//
//  Created by KUN on 17/6/28.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SKOpenGLView : UIView

- (void)displayWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
