
#import "SKCamera+Helper.h"

@implementation SKCamera (Helper)

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
