//
//  SKCamera+Helper.m
//  SKCamera
//
//  Created by KUN on 17/1/13.
//  Copyright © 2017年 NULL. All rights reserved.
//
#import "SKCamera+Helper.h"

@implementation SKCamera (Helper)

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


+ (CVPixelBufferRef)pixelBufferFromCGImage2:(CGImageRef)image
{
    
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height,  kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

//转换图片
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    
    return (image);
}


+ (UIImage *)imageFromSampleBuffer2:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) {
        NSLog(@"CGColorSpaceCreateDeviceRGB failure");
        return nil;
    }
    
    // Get the base address of the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize,
                                                              NULL);
    // Create a bitmap image from data supplied by our data provider
    CGImageRef cgImage =
    CGImageCreate(width,
                  height,
                  8,
                  32,
                  bytesPerRow,
                  colorSpace,
                  kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  provider,
                  NULL,
                  true,
                  kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    // Create and return an image object representing the specified Quartz image
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}



//CMSampleBufferRef转换成image
+(UIImage *) imageFromSampleBuffer3:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return image;
}




/**
 CVPixelBufferRef 转换为UIimage
 
 @param pixelBufffer 图片的CVPixelBufferRef
 @return UIimage
 */
#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit

+(UIImage*)pixelBufferToImage:(CVPixelBufferRef) pixelBufffer{
    CVPixelBufferLockBaseAddress(pixelBufffer, 0);// 锁定pixel buffer的基地址
    void * baseAddress = CVPixelBufferGetBaseAddress(pixelBufffer);// 得到pixel buffer的基地址
    size_t width = CVPixelBufferGetWidth(pixelBufffer);
    size_t height = CVPixelBufferGetHeight(pixelBufffer);
    size_t bufferSize = CVPixelBufferGetDataSize(pixelBufffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBufffer);// 得到pixel buffer的行字节数
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();// 创建一个依赖于设备的RGB颜色空间
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       kBitsPerComponent,
                                       kBitsPerPixel,
                                       bytesPerRow,
                                       rgbColorSpace,
                                       kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       true,
                                       kCGRenderingIntentDefault);//这个是建立一个CGImageRef对象的函数
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);  //类似这些CG...Ref 在使用完以后都是需要release的，不然内存会有问题
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    NSData* imageData = UIImageJPEGRepresentation(image, 1.0);//1代表图片是否压缩
    image = [UIImage imageWithData:imageData];
    CVPixelBufferUnlockBaseAddress(pixelBufffer, 0);   // 解锁pixel buffer
    
    return image;
}

+ (void)cutVideoWith:(NSString *)videoPath
              saveTo:(NSString *)totalPath
           videoSize:(CGSize)videoSize
        fromCutPoint:(CGPoint)cutPoint
         shouldScale:(BOOL)shouldScale
             success:(void(^)(NSString *outPutPath))success
                fail:(void(^)())fail {
    
    NSError *error = nil;
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    
    AVAssetTrack *assetAudioTrack ;
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetAudioTrack
                             atTime:kCMTimeZero
                              error:&error];
    }
    
    AVAssetTrack *assetVideoTrack ;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0){
        assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    } else {
        assetVideoTrack = nil;
        fail();
        return;
    }
    
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                        ofTrack:assetVideoTrack
                         atTime:kCMTimeZero
                          error:&error];
    if (error) {
        NSLog(@"videoTrack error.description：%@",error.description);
        fail();
        return;
    }
    
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetvertical  = NO;
    CGAffineTransform videoTransform = assetVideoTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        isVideoAssetvertical = YES;
        videoAssetOrientation_ =  UIImageOrientationUp;//正着拍
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        isVideoAssetvertical = YES;
        videoAssetOrientation_ = UIImageOrientationDown;//倒着拍
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        isVideoAssetvertical = NO;
        videoAssetOrientation_ =  UIImageOrientationLeft;//左边拍的
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        isVideoAssetvertical = NO;
        videoAssetOrientation_ = UIImageOrientationRight;//右边拍
    }
    
    float scaleX = 1.0,scaleY = 1.0,scale = 1.0;
    CGSize originVideoSize;
    if (isVideoAssetvertical) {
        originVideoSize = CGSizeMake([[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize].height, [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize].width);
    }
    else{
        originVideoSize = CGSizeMake([[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize].width, [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize].height);
    }
    
    /////////  (CGSize) originVideoSize = (width = 720, height = 1280)  // 后置
    
    ////////// (CGSize) originVideoSize = (width = 1280, height = 720)  // 前置
    
    float x = cutPoint.x;
    float y = cutPoint.y;
    if (shouldScale) {
        scaleX = videoSize.width/originVideoSize.width;
        scaleY = videoSize.height/originVideoSize.height;
        scale  = MAX(scaleX, scaleY);
        if (scaleX>scaleY) { /// 竖屏
        } else{  /// 横屏
        }
    }
    else {
        scaleX = 1.0;
        scaleY = 1.0;
        scale = 1.0;
    }
    
    
    CGSize naturalSize;
    naturalSize = originVideoSize;
    int64_t renderWidth = 0, renderHeight = 0;
    if (videoSize.height ==0.0 || videoSize.width == 0.0) {
        renderWidth = naturalSize.width;
        renderHeight = naturalSize.height;
    }
    else{
        renderWidth = ceil(videoSize.width);
        renderHeight = ceil(videoSize.height);
    }
    
    naturalSize.width = MAX(naturalSize.width, originVideoSize.height);
    naturalSize.height = MAX(naturalSize.height, originVideoSize.width);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    CGAffineTransform trans = CGAffineTransformMake(assetVideoTrack.preferredTransform.a*scale, assetVideoTrack.preferredTransform.b*scale, assetVideoTrack.preferredTransform.c*scale, assetVideoTrack.preferredTransform.d*scale, assetVideoTrack.preferredTransform.tx*scale-x, assetVideoTrack.preferredTransform.ty*scale-y);
    //
    //    //保证视频为垂直正确的方向
    //    CGAffineTransform t2 = CGAffineTransformRotate(trans, M_PI_2);
    //    CGAffineTransform finalTransform = t2;
    //    [layerInstruciton setTransform:finalTransform atTime:kCMTimeZero];
    
    
    [layerInstruciton setTransform:trans atTime:kCMTimeZero];
    [layerInstructionArray addObject:layerInstruciton];
    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
    mainInstruciton.layerInstructions = layerInstructionArray;
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:totalPath]) {
            NSError *error = nil;
            [fileManager removeItemAtPath:totalPath error:&error];
        }
    });
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainCompositionInst;
    NSURL *totalURL = [NSURL fileURLWithPath:totalPath];
    exporter.outputURL = totalURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"exporter.status == %ld",(long)exporter.status);
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                NSURL *outputURLNew = exporter.outputURL;
                if (success) {
                    success(outputURLNew.path);
                }
            } else if (exporter.status == AVAssetExportSessionStatusFailed) {
                NSLog(@"exporting failed %@",[exporter error]);
                fail();
            }else {
                fail();
            }
        });
    }];
}


- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
                                          previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
                                                 ports:(NSArray<AVCaptureInputPort *> *)ports
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = previewLayer.frame.size;
    
    if ( [previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in ports) {
            if (port.mediaType == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

- (UIImage *)cropImage:(UIImage *)image usingPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
{
    CGRect previewBounds = previewLayer.bounds;
    CGRect outputRect = [previewLayer metadataOutputRectOfInterestForRect:previewBounds];
    
    CGImageRef takenCGImage = image.CGImage;
    size_t width = CGImageGetWidth(takenCGImage);
    size_t height = CGImageGetHeight(takenCGImage);
    CGRect cropRect = CGRectMake(outputRect.origin.x * width, outputRect.origin.y * height,
                                 outputRect.size.width * width, outputRect.size.height * height);
    
    CGImageRef cropCGImage = CGImageCreateWithImageInRect(takenCGImage, cropRect);
    image = [UIImage imageWithCGImage:cropCGImage scale:1 orientation:image.imageOrientation];
    CGImageRelease(cropCGImage);
    
    return image;
}


@end


@implementation SKFocusLayer

- (void)layoutSublayers {
    
    [super layoutSublayers];
    
    self.bigCircleLayer.bounds = CGRectMake(0.0f, 0.0f, 60, 60);
    self.smallCircleLayer.bounds = CGRectMake(0.0f, 0.0f, 46, 46);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        CALayer *bigCircleLayer = [[CALayer alloc] init];
        bigCircleLayer.cornerRadius = 30;
        bigCircleLayer.borderColor = [UIColor whiteColor].CGColor;
        bigCircleLayer.bounds = CGRectMake(0.0f, 0.0f, 60, 60);
        bigCircleLayer.borderWidth = 1.0f;
        bigCircleLayer.opacity = 1.0f;
        bigCircleLayer.shadowOffset = CGSizeMake(0, 0);
        bigCircleLayer.shadowRadius = 1.0;
        bigCircleLayer.shadowColor = [UIColor whiteColor].CGColor;
        bigCircleLayer.shadowOpacity = 0.8;
        self.bigCircleLayer = bigCircleLayer;
        [self addSublayer:bigCircleLayer];
        
        CALayer *smallCircleLayer = [[CALayer alloc] init];
        smallCircleLayer.cornerRadius = 23;
        smallCircleLayer.borderColor = [UIColor whiteColor].CGColor;
        smallCircleLayer.bounds = CGRectMake(0.0f, 0.0f, 46, 46);
        smallCircleLayer.borderWidth = 2.0f;
        smallCircleLayer.opacity = 1.0f;
        smallCircleLayer.shadowOffset = CGSizeMake(0, 0);
        smallCircleLayer.shadowRadius = 2.0;
        smallCircleLayer.shadowColor = [UIColor whiteColor].CGColor;
        smallCircleLayer.shadowOpacity = 0.8;
        smallCircleLayer.position = CGPointMake(0, 0);
        self.smallCircleLayer = smallCircleLayer;
        [self addSublayer: smallCircleLayer];
        
        [self config];
    }
    return self;
}

-(void)config {
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = 0.3;
    opacityAnimation.autoreverses = NO;
    opacityAnimation.repeatCount = 0.0;
    opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    opacityAnimation.toValue = [NSNumber numberWithFloat:0.0];
    self.opacityAnimation = opacityAnimation;
    
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.duration = 1.0;
    scaleAnimation.autoreverses = NO;
    scaleAnimation.repeatCount = HUGE_VALF;
    scaleAnimation.fillMode = kCAFillModeBoth;
    scaleAnimation.calculationMode = kCAAnimationCubic;
    scaleAnimation.values = @[@(1.0), @(1.4), @(1.0), @(1.3), @(1.0)];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.delegate = self;
    group.animations = @[scaleAnimation];
    group.duration = 1.0;
    self.scaleAnimation = group;
    
}

- (void)showFocusAnimation {
    
    if (_isFocusAnimating) {
        return;
    }
    [self.bigCircleLayer removeAllAnimations];
    self.bigCircleLayer.opacity = 1.0;
    self.opacity = 1.0;
    [self.bigCircleLayer addAnimation:self.scaleAnimation forKey:@"scaleAnimation"];
}

- (void)animationDidStart:(CAAnimation *)anim {
    _isFocusAnimating = YES;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    _isFocusAnimating = NO;
    
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    [CATransaction setValue:[NSNumber numberWithFloat:0.2]
                     forKey:kCATransactionAnimationDuration];
    self.opacity = 0.0;
    [CATransaction commit];
}
@end

