//
//  SKCamera.h
//  SKCamera
//
//  Created by KUN on 17/1/13.
//  Copyright © 2017年 NULL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


/**
 *  @brief  前后摄像头
 */
typedef NS_ENUM(NSInteger, SKCameraPosition) {
    SKCameraPosition_Front = 0,
    SKCameraPosition_Back = 1
};


/**
 *  @brief  闪光灯
 */
typedef NS_ENUM(NSInteger, SKCameraFlash) {
    SKCameraFlashOff = 0,
    SKCameraFlashOn = 1,
    SKCameraFlashAuto
};

/**
 *  @brief 镜像mirror
 */
typedef NS_ENUM(NSInteger, SKCameraMirror) {
    SKCameraMirrorOff = 0,
    SKCameraMirrorOn = 1,
    SKCameraMirrorAuto
};


extern NSString *const SKCameraErrorDomain;

/**
 *  @brief  错误码
 */
typedef NS_ENUM(NSInteger, SKCameraErrorCode) {
    SKCameraErrorCodeCameraPermission = 10,
    SKCameraErrorCodeMicrophonePermission = 11,
    SKCameraErrorCodeSession = 12,
    SKCameraErrorCodeVideoNotEnabled = 13
};



@interface SKCamera : NSObject

/**
 * 预览的view
 */
@property (nonatomic, strong) UIView * previewView;

@property (nonatomic, weak) id<AVCaptureVideoDataOutputSampleBufferDelegate> captureDelegate;
@property (nonatomic, weak) id<AVCaptureMetadataOutputObjectsDelegate> faceDetectionDelegate;
@property (nonatomic, weak) id<AVCaptureAudioDataOutputSampleBufferDelegate> audioDelegate;

@property (nonatomic, readonly) dispatch_queue_t cameraQueue;
@property (nonatomic, readonly) dispatch_queue_t metadataQueue;
@property (nonatomic, readonly) dispatch_queue_t audioQueue;

@property (nonatomic, readonly) dispatch_queue_t sessionQueue; //

@property (nonatomic, strong, readonly) AVCaptureConnection* videoConnection;
@property (nonatomic, strong, readonly) AVCaptureConnection* audioConnection;


/**
 * 切换摄像头回调
 */
@property (nonatomic, copy) void (^onDeviceChange)(SKCamera *camera, AVCaptureDevice *device);

/**
 * 各种错误回调
 */
@property (nonatomic, copy) void (^onError)(SKCamera *camera, NSError *error);

/**
 * 开始录视频回调
 */
@property (nonatomic, copy) void (^onStartRecording)(SKCamera *camera);

/**
 * 视频质量  eg. AVCaptureSessionPresetHigh
 */
@property (nonatomic, copy) NSString *cameraQuality;

@property (nonatomic, readonly) CGSize imageSize;

/**
 * 闪关灯模式
 */
@property (nonatomic, readonly) SKCameraFlash flash;

/**
 * 镜像mirror
 */
@property (nonatomic) SKCameraMirror mirror;

@property (nonatomic) SKCameraPosition position;

/**
 * 白平衡
 */
@property (nonatomic) AVCaptureWhiteBalanceMode whiteBalanceMode;

/**
 * 以下输出都是打开的,如果不需要再单独关闭
 * Default is Enabled
 */
@property (nonatomic, getter=isVideoOutputEnabled) BOOL videoOutputEnabled; // videoOutput
@property (nonatomic, getter=isAudioOutputEnabled) BOOL audioOutputEnabled; // audioOutput
@property (nonatomic, getter=isPhotoOutputEnabled) BOOL photoOutputEnabled; // photoOutput
@property (nonatomic, getter=isFaceDetectEnabled)  BOOL faceDetectEnabled; // face detect

/**
 *  是否需要录制视频文件
 *  Default is DisEnabled
 */
@property (nonatomic, getter=isNeedRecord) BOOL needRecord;

@property (nonatomic, getter=isVideoEnabled) BOOL videoEnabled;

@property (nonatomic, getter=isRecording) BOOL recording;

@property (nonatomic, getter=isZoomingEnabled) BOOL zoomingEnabled;

//@property (nonatomic, assign) CGFloat maxScale;

@property (nonatomic) BOOL fixOrientationAfterCapture;

/**
 * 点击对焦
 */
@property (nonatomic) BOOL tapToFocus;

/**
 * 需要自动旋转屏幕 ： set NO
 * 不自动旋转屏幕 ： set YES
 */
@property (nonatomic) BOOL useDeviceOrientation;

+ (SKCamera *)camera;

- (instancetype)initWithQuality:(NSString *)quality position:(SKCameraPosition)position videoEnabled:(BOOL)videoEnabled;

- (instancetype)initWithVideoQuality:(NSString *)quality position:(SKCameraPosition)position captureDelegate:(id)delegate;


/**
 * 在设置delegate 之前调用
 */
- (void)prepare ;

/**
 * start running session
 */
- (void)startRunnig;

/**
 * stop runnig session
 */
- (void)stopRunnig;

/**
 * 拍照
 *
 * @param exactSeenImage   YES: 剪切到 preview 大小一样
 * @param animationBlock   拍照的时候加入自己的动画效果
 */
-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage animationBlock:(void (^)(AVCaptureVideoPreviewLayer *))animationBlock;

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage;

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture;


/*
 * 开始录制视频
 *
 * @param url   视频输出的url
 */
- (void)startRecordingWithOutputUrl:(NSURL *)url didRecord:(void (^)(SKCamera *camera, NSURL *outputFileUrl, NSError *error))completionBlock;

/**
 * 停止录制视频
 */
- (void)stopRecording;


/**
 * 切换摄像头
 */
- (SKCameraPosition)togglePosition;

/**
 * 设置闪光灯模式
 */
- (BOOL)updateFlashMode:(SKCameraFlash)cameraFlash;

/**
 * 检查闪光灯是否可用 (For Video)
 */
- (BOOL)isFlashAvailable;

/**
 * 检查闪光灯是否可用
 */
- (BOOL)isTorchAvailable;

/**
 * 自定义 对焦 动画
 */
- (void)alterFocusBox:(CALayer *)layer animation:(CAAnimation *)animation;


#pragma mark - Class Methods
/**
 * 请求相机权限
 */
+ (void)requestCameraPermission:(void (^)(BOOL granted))completionBlock;

/**
 * 请求麦克风权限
 */
+ (void)requestMicrophonePermission:(void (^)(BOOL granted))completionBlock;


/**
 * 检查 前置摄像头是否可用
 */
+ (BOOL)isFrontCameraAvailable;

/**
 * 检查 后置摄像头是否可用
 */
+ (BOOL)isRearCameraAvailable;

@end
