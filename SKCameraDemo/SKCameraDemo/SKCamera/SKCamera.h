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
 * 正在录视频回调
 */
@property (nonatomic, copy) void (^onRecordingTimeBlock)(SKCamera *camera , CGFloat currentRecordTime , CGFloat maxRecordTime);

/**
 * 录视频完成回调
 */
@property (nonatomic, copy) void (^didRecordCompletionBlock)(SKCamera *camera, NSURL *outputFileUrl, NSError *error);

/**
 * 视频质量  eg. AVCaptureSessionPresetHigh
 */
@property (nonatomic, copy) NSString *cameraQuality;

/**
 * 图片大小
 */
@property (nonatomic, readonly) CGSize imageSize;

/**
 * 闪关灯模式
 */
@property (nonatomic, readonly) SKCameraFlash flash;

/**
 * 镜像mirror
 */
@property (nonatomic) SKCameraMirror mirror;

/**
 * 相机前后置
 */
@property (nonatomic) SKCameraPosition position;

/**
 * 白平衡
 */
@property (nonatomic) AVCaptureWhiteBalanceMode whiteBalanceMode;

/**
 * 以下输出都是打开的,如果不需要再单独关闭
 * default is enabled
 */
@property (nonatomic, getter=isVideoOutputEnabled) BOOL videoOutputEnabled; // videoOutput
@property (nonatomic, getter=isAudioOutputEnabled) BOOL audioOutputEnabled; // audioOutput
@property (nonatomic, getter=isPhotoOutputEnabled) BOOL photoOutputEnabled; // photoOutput
/**
 * metadata default is unenabled
 */
@property (nonatomic, getter=isFaceDetectEnabled)  BOOL faceDetectEnabled;  // face detect

/**
 *  是否需要录制视频文件
 *  Default is DisEnabled
 */
@property (nonatomic, getter=isNeedRecord)     BOOL needRecord;
@property (nonatomic, getter=isVideoEnabled)   BOOL videoEnabled;
@property (nonatomic, getter=isZoomingEnabled) BOOL zoomingEnabled;

/**
 * readonly
 */
@property (nonatomic, getter=isRecording , readonly)  BOOL recording; // 是否正在录制
@property (nonatomic, getter=isPaused ,    readonly)  BOOL paused;  // 是否暂停
@property (nonatomic, getter=isDiscont ,   readonly)  BOOL discont; // 是否中断

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
 * 在设置delegate 之后调用
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
-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture
exactSeenImage:(BOOL)exactSeenImage
animationBlock:(void (^)(AVCaptureVideoPreviewLayer *))animationBlock;

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage;

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture;

/*
 * 设置录制视频 相关信息
 *
 * @param url   视频输出的url
 * @param cropFrame   需要录制区域的frame，如果录制的是preview的区域, 就传 CGRectZero
 * @param maxRecordTime   最大录制时间 , 单位:秒  例如60.f
 */
- (void)setupRecordingConfigWithOutputUrl:(NSURL *)url  cropFrame:(CGRect)cropFrame maxRecordTime:(CGFloat)maxRecordTime;

/**
 * 开启录制功能
 */
- (void)sk_enableRecording ;

/**
 * 关闭录制功能
 */
- (void)sk_shutRecording ;

/**
 * 开始录制视频  (可以设置 录制的 区域)
 */
- (void)sk_startRecording;

/**
 * 暂停录制视频
 */
- (void)sk_pauseRecording;

/**
 * 继续录制视频
 */
- (void)sk_resumeRecording;

/**
 * 停止录制视频
 */
- (void)sk_stopRecording;

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

/**
 * 销毁相机画
 */
- (void)destroyCamera;


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
