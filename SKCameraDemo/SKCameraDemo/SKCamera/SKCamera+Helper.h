//
//  SKCamera+Helper.h
//  SKCamera
//
//  Created by KUN on 17/1/13.
//  Copyright © 2017年 NULL. All rights reserved.
//

#import "SKCamera.h"

@interface SKCamera (Helper)

/**
 CMSampleBufferRef 转 UIImage
 */
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

//CMSampleBufferRef转换成image
+(UIImage *) imageFromSampleBuffer2:(CMSampleBufferRef) sampleBuffer;

//CMSampleBufferRef转换成image
+(UIImage *) imageFromSampleBuffer3:(CMSampleBufferRef) sampleBuffer;


+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;

/**
 视频剪切
 
 @param videoPath 原视频文件
 @param totalPath 剪切后保存的地址
 @param videoSize 剪切区域的大小
 @param cutPoint 剪切区域的 左上角 点
 @param shouldScale 是否缩放, always true
 @param success 成功回调
 @param fail 失败
 */
+ (void)cutVideoWith:(NSString *)videoPath
              saveTo:(NSString *)totalPath
           videoSize:(CGSize)videoSize
        fromCutPoint:(CGPoint)cutPoint
         shouldScale:(BOOL)shouldScale
             success:(void(^)(NSString *outPutPath))success
                fail:(void(^)())fail;


- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
                                          previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
                                                 ports:(NSArray<AVCaptureInputPort *> *)ports;

- (UIImage *)cropImage:(UIImage *)image usingPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;

@end


/**
 对焦动画的layer
 */
@interface SKFocusLayer : CALayer <CAAnimationDelegate>
{
    BOOL _isFocusAnimating;
}

@property (nonatomic , strong) CALayer *bigCircleLayer;
@property (nonatomic , strong) CALayer *smallCircleLayer;
@property (nonatomic , strong) CAAnimation  *scaleAnimation;// 对焦动画
@property (nonatomic , strong) CAAnimation  *opacityAnimation;// 对焦动画

- (void)showFocusAnimation ;
@end
