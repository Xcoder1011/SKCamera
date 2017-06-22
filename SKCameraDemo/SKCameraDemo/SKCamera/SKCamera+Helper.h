
#import "SKCamera.h"

@interface SKCamera (Helper)



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
