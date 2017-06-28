//
//  SKCamera.m
//  SKCamera
//
//  Created by KUN on 17/1/13.
//  Copyright © 2017年 NULL. All rights reserved.
//

#import "SKCamera.h"

#import <ImageIO/CGImageProperties.h>
#import "UIImage+Utils.h"
#import "SKCamera+Helper.h"
#import "SKOpenGLView.h"

@interface SKCamera () <AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate >
{
    UIView *_previewView;
    int _beginSessionConfigurationCount;
    BOOL _videoOutputAdded;
    BOOL _audioOutputAdded;
    BOOL _metadataOutputAdded;
    
    BOOL _useAssetWriter;
    
    CMTime _currentSampleTime;
    // 需要录制的区域 frame
    CGRect _cropFrame;
    
    CMTime  _startRecordTime; // 开始录制的时间
    CGFloat _currentRecordTime; // 当前录制时间
    
    CGFloat _maxRecordTime; // 录制最长时间
    
    
    CMTime _timeOffset;//录制的偏移CMTime
    CMTime _lastVideoTime;//记录上一次视频数据文件的CMTime
    CMTime _lastAudioTime;//记录上一次音频数据文件的CMTime

}

@property (strong, nonatomic) AVCaptureSession           *session;   // 捕捉视频会话
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer; // 视频显示layer
@property (strong ,  nonatomic) SKOpenGLView *openGLView;

@property (strong, nonatomic) AVCaptureDeviceInput       *audioDeviceInput; // 麦克风输入
@property (strong, nonatomic) AVCaptureDeviceInput       *videoDeviceInput; // 视频输入
@property (strong, nonatomic) AVCaptureDevice            *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDevice            *audioCaptureDevice;


@property (strong, nonatomic) AVCaptureAudioDataOutput   *audioDataOutput; // 音频输出
@property (strong, nonatomic) AVCaptureVideoDataOutput   *videoDataOutput; // 视频输出
@property (strong, nonatomic) AVCaptureMetadataOutput    *metadataOutput;  // 人脸追踪


@property (strong, nonatomic) AVCaptureStillImageOutput  *photoOutput; //
@property (strong, nonatomic) AVCaptureMovieFileOutput   *movieFileOutput; // 录制视频输出


@property (nonatomic, strong, readwrite) AVCaptureConnection* videoConnection;
@property (nonatomic, strong, readwrite) AVCaptureConnection* audioConnection;

/**
 *  刻录机
 */
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoAssetWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioAssetWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;  //缓冲区


@property (strong, nonatomic) UITapGestureRecognizer     *tapGesture; // 点击对焦手势
@property (strong, nonatomic) UIPinchGestureRecognizer   *pinchGesture; // 捏合缩放
@property (strong, nonatomic) CALayer                    *focusBoxLayer; // 对焦动画layer
@property (strong, nonatomic) CAAnimation                *focusBoxAnimation;// 对焦动画

@property (assign, nonatomic) CGFloat                    beginGestureScale; // 初始放大系数
@property (assign, nonatomic) CGFloat                    effectiveScale; // 最终放大系数

@property (weak, nonatomic)   id                        delegate; // controller delegate


@property (nonatomic, strong) dispatch_queue_t cameraQueue;
@property (nonatomic, strong) dispatch_queue_t metadataQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;

@property (nonatomic, strong) dispatch_queue_t sessionQueue; //


@property (copy, nonatomic) void (^didRecordCompletionBlock)(SKCamera *camera, NSURL *outputFileUrl, NSError *error);  // 录制完成

@property (readonly, nonatomic) NSError *__nullable error;

/**
 * readwrite
 */
@property (nonatomic, getter=isRecording , readwrite)  BOOL recording; // 是否正在录制
@property (nonatomic, getter=isPaused ,    readwrite)  BOOL paused;  // 是否暂停
@property (nonatomic, getter=isDiscont ,   readwrite)  BOOL discont; // 是否中断


@end



@implementation SKCamera

NSString *const SKCameraErrorDomain = @"SKCameraErrorDomain";

#pragma mark - Initialize

+ (SKCamera *)camera {
    return [[SKCamera alloc] init];
}

- (instancetype)init
{
    return [self initWithQuality:AVCaptureSessionPreset640x480 position:SKCameraPosition_Front videoEnabled:YES];
}

- (instancetype)initWithQuality:(NSString *)quality position:(SKCameraPosition)position videoEnabled:(BOOL)videoEnabled
{
    
    self =  [super init];
    if(self) {
        [self setupWithQuality:quality position:position videoEnabled:videoEnabled];
        [self _initialWithSKCmaera];
    }
    
    return self;
}

- (instancetype)initWithVideoQuality:(NSString *)quality position:(SKCameraPosition)position captureDelegate:(id)delegate {
    
    self =  [super init];
    if(self) {
        [self setupWithQuality:quality position:position videoEnabled:YES];
        [self _initialWithSKCmaera];
        if (delegate) {
            self.delegate = delegate;
        } else {
            self.delegate = self;
        }
    }
    return self;
}


- (void)setupWithQuality:(NSString *)quality
                position:(SKCameraPosition)position
            videoEnabled:(BOOL)videoEnabled
{
    self.cameraQuality = quality;
    _position = position;
    _fixOrientationAfterCapture = NO;
    _tapToFocus = YES;
    _useDeviceOrientation = NO;
    _flash = SKCameraFlashOff;
    _mirror = SKCameraMirrorAuto;
    _videoEnabled = videoEnabled;
    _recording = NO;
    _needRecord = NO;
    _zoomingEnabled = YES;
    _effectiveScale = 1.0f;
    _useAssetWriter = NO;
    
    _videoOutputEnabled = YES;
    _audioOutputEnabled  = YES;
    _photoOutputEnabled = YES;
    _faceDetectEnabled = NO;
    
    _maxRecordTime = 60.f;
    
    _beginSessionConfigurationCount = 0;
}

-(void)_initialWithSKCmaera {
    
    _sessionQueue = dispatch_queue_create("com.skcamera.sessionQueue", nil);
    dispatch_queue_set_specific(_sessionQueue, "SKCameraRecordSessionQueue", "true", nil);
    dispatch_set_target_queue(_sessionQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
}


- (void) addCustomGesture {
    
    // tap to focus
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewTapped:)];
    self.tapGesture.numberOfTapsRequired = 1;
    [self.tapGesture setDelaysTouchesEnded:NO];
    [self.previewView addGestureRecognizer:self.tapGesture];
    
    //pinch to zoom
    if (_zoomingEnabled) {
        self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        self.pinchGesture.delegate = self;
        [self.previewView addGestureRecognizer:self.pinchGesture];
    }
    
    // add focus box to view
    [self addDefaultFocusBox];
    
}


#pragma mark Pinch Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _beginGestureScale = _effectiveScale;
    }
    return YES;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.previewView];
        CGPoint convertedLocation = [self.previewView.layer convertPoint:location fromLayer:[self previewView].superview.layer]; // new add
        if ( ! [self.previewView.layer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if (allTouchesAreOnThePreviewLayer) {
        _effectiveScale = _beginGestureScale * recognizer.scale;
        if (_effectiveScale < 1.0f)
            _effectiveScale = 1.0f;
        if (_effectiveScale > self.videoCaptureDevice.activeFormat.videoMaxZoomFactor)
            _effectiveScale = self.videoCaptureDevice.activeFormat.videoMaxZoomFactor;
        NSError *error = nil;
        if ([self.videoCaptureDevice lockForConfiguration:&error]) {
            [self.videoCaptureDevice rampToVideoZoomFactor:_effectiveScale withRate:100];
            [self.videoCaptureDevice unlockForConfiguration];
        } else {
            [self passError:error];
        }
    }
}

#pragma mark - Camera

- (void)prepare {
    
    [SKCamera requestCameraPermission:^(BOOL granted) {
        if(granted) {
            // request microphone permission if video is enabled
            if(self.videoEnabled) {
                [SKCamera requestMicrophonePermission:^(BOOL granted) {
                    if(granted) {
                        [self initialize];
                    }
                    else {
                        NSError *error = [NSError errorWithDomain:SKCameraErrorDomain
                                                             code:SKCameraErrorCodeMicrophonePermission
                                                         userInfo:nil];
                        [self passError:error];
                    }
                }];
            }
            else {
                [self initialize];
            }
        }
        else {
            NSError *error = [NSError errorWithDomain:SKCameraErrorDomain
                                                 code:SKCameraErrorCodeCameraPermission
                                             userInfo:nil];
            [self passError:error];
        }
    }];
    
}


- (void)startRunnig
{
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}


- (void)stopRunnig
{
    [self.session stopRunning];
}

- (BOOL)prepare:(NSError **)error {
    if (_session != nil) {
        [NSException raise:@"SKCameraException" format:@"The session is already opened"];
    }
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.automaticallyConfiguresApplicationAudioSession = YES;
    session.sessionPreset = self.cameraQuality;
    _session = session;
    
    _beginSessionConfigurationCount = 0;
    
    [self beginConfiguration];
    
    BOOL success = [self _reconfigureSession];
    
    if (!success && error != nil) {
        *error = _error;
    }
    
    _captureVideoPreviewLayer.session = session;
    
    //    [self reconfigureVideoInput:YES audioInput:YES];
    
    [self commitConfiguration];
    
    return success;
}

- (void)beginConfiguration {
    if (_session != nil) {
        _beginSessionConfigurationCount++;
        if (_beginSessionConfigurationCount == 1) {
            [_session beginConfiguration];
        }
    }
}

- (void)commitConfiguration {
    if (_session != nil) {
        _beginSessionConfigurationCount--;
        if (_beginSessionConfigurationCount == 0) {
            [_session commitConfiguration];
        }
    }
}

+ (NSError*)createError:(NSString*)errorDescription code:(SKCameraErrorCode)code{
    
    return  [NSError errorWithDomain: SKCameraErrorDomain
                                code: code
                            userInfo: @{NSLocalizedDescriptionKey : errorDescription}];
}


- (BOOL)_reconfigureSession {
    
    NSError *newError = nil;
    
    AVCaptureSession *session = _session;
    
    if (session != nil) {
        [self beginConfiguration];
        
        if (![session.sessionPreset isEqualToString:_cameraQuality]) {
            if ([session canSetSessionPreset:_cameraQuality]) {
                session.sessionPreset = _cameraQuality;
            } else {
                newError = [SKCamera createError:@"Cannot set session preset" code:SKCameraErrorCodeSession];
            }
        }
        
        if (_movieFileOutput != nil && [session.outputs containsObject:_movieFileOutput]) {
            [session removeOutput:_movieFileOutput];
        }
        
        _videoOutputAdded = NO;
        
        if (self.videoOutputEnabled) {
            
            if (_videoDataOutput == nil) {
                _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
                _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
                [_videoDataOutput setSampleBufferDelegate:self queue:_sessionQueue];
            }
            
            
            if (![session.outputs containsObject:_videoDataOutput]) {
                if ([session canAddOutput:_videoDataOutput]) {
                    [session addOutput:_videoDataOutput];
                    _videoOutputAdded = YES;
                } else {
                    if (newError == nil) {
                        newError = [SKCamera createError:@"Cannot add videoOutput inside the session" code:SKCameraErrorCodeSession];
                    }
                }
            } else {
                _videoOutputAdded = YES;
            }
        }
        
        _audioOutputAdded = NO;
        if (self.audioOutputEnabled) {
            if (_audioDataOutput == nil) {
                _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
                [_audioDataOutput setSampleBufferDelegate:self queue:_sessionQueue];
            }
            
            if (![session.outputs containsObject:_audioDataOutput]) {
                if ([session canAddOutput:_audioDataOutput]) {
                    [session addOutput:_audioDataOutput];
                    _audioOutputAdded = YES;
                } else {
                    if (newError == nil) {
                        newError = [SKCamera createError:@"Cannot add audioOutput inside the sesssion" code:SKCameraErrorCodeSession];
                    }
                }
            } else {
                _audioOutputAdded = YES;
            }
        }
        
        if (self.photoOutputEnabled) {
            if (_photoOutput == nil) {
                _photoOutput = [[AVCaptureStillImageOutput alloc] init];
                NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
                [_photoOutput setOutputSettings:outputSettings];
            }
            
            if (![session.outputs containsObject:_photoOutput]) {
                if ([session canAddOutput:_photoOutput]) {
                    [session addOutput:_photoOutput];
                } else {
                    if (newError == nil) {
                        newError = [SKCamera createError:@"Cannot add photoOutput inside the session" code:SKCameraErrorCodeSession];
                    }
                }
            }
        }
        
        [self commitConfiguration];
    }
    _error = newError;
    
    return newError == nil;
}



- (void)initialize
{
    if(!_session) {
        _session = [[AVCaptureSession alloc] init];
        _session.sessionPreset = self.cameraQuality;
        
        [_captureVideoPreviewLayer removeFromSuperlayer];
        
        // preview layer
        CGRect bounds = self.previewView.layer.bounds;
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _captureVideoPreviewLayer.bounds = bounds;
        _captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        
        // [self openGLView];

        if (_previewView != nil) {  // new add
            [_previewView.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
            [self previewViewFrameChanged];
        }
        
        AVCaptureDevicePosition devicePosition;
        switch (self.position) {
            case SKCameraPosition_Back:
                if([self.class isRearCameraAvailable]) {
                    devicePosition = AVCaptureDevicePositionBack;
                } else {
                    devicePosition = AVCaptureDevicePositionFront;
                    _position = SKCameraPosition_Front;
                }
                break;
            case SKCameraPosition_Front:
                if([self.class isFrontCameraAvailable]) {
                    devicePosition = AVCaptureDevicePositionFront;
                } else {
                    devicePosition = AVCaptureDevicePositionBack;
                    _position = SKCameraPosition_Back;
                }
                break;
            default:
                devicePosition = AVCaptureDevicePositionUnspecified;
                break;
        }
        
        if(devicePosition == AVCaptureDevicePositionUnspecified) {
            self.videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        } else {
            self.videoCaptureDevice = [self cameraWithPosition:devicePosition];
        }
        
        NSError *error = nil;
        _videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoCaptureDevice error:&error];
        
        if (!_videoDeviceInput) {
            [self passError:error];
            return;
        }
        
        if([self.session canAddInput:_videoDeviceInput]) {
            [self.session  addInput:_videoDeviceInput];
            self.captureVideoPreviewLayer.connection.videoOrientation = [self orientationForConnection];
        }
        
        // add audio if video is enabled
        if(self.videoEnabled) {
            _audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            _audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioCaptureDevice error:&error];
            if (!_audioDeviceInput) {
                [self passError:error];
            }
            
            if([self.session canAddInput:_audioDeviceInput]) {
                [self.session addInput:_audioDeviceInput];
            }
        }
        
        
        // add video output
        _videoOutputAdded = NO;
        if (self.videoOutputEnabled) {
            
            if (![self.session.outputs containsObject:self.videoDataOutput]) {
                
                if ([self.session canAddOutput:self.videoDataOutput]) {
                    [self.session addOutput:self.videoDataOutput];
                    _videoOutputAdded = YES;
                    _videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
//                    _videoConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
//                    _videoConnection.automaticallyAdjustsVideoMirroring = NO;
                    
//                    if ([_videoConnection isVideoOrientationSupported]) {
//                        [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
//                    }
                    
                    // 标识视频录入时稳定音频流的接受，我们这里设置为自动
                    if(_videoConnection.isVideoStabilizationSupported){
                        _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                    }
                    
                } else {
                    if (error == nil) {
                        error = [SKCamera createError:@"Cannot add videoOutput inside the session" code:SKCameraErrorCodeSession];
                        [self passError:error];
                    }
                }
            } else {
                _videoOutputAdded = YES;
            }
        }
        
        
        // add audio output
        _audioOutputAdded = NO;
        if (self.audioOutputEnabled) {
            
            if (![self.session.outputs containsObject:self.audioDataOutput]) {
                if ([self.session canAddOutput:self.audioDataOutput]) {
                    [self.session addOutput:self.audioDataOutput];
                    _audioOutputAdded = YES;
                    _audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
                    
                } else {
                    if (error == nil) {
                        error = [SKCamera createError:@"Cannot add audioOutput inside the sesssion" code:SKCameraErrorCodeSession];
                        [self passError:error];
                    }
                }
            } else {
                _audioOutputAdded = YES;
            }
        }
        
        
        // add photo output
        if (self.photoOutputEnabled) {
            
            if (![self.session.outputs containsObject:self.photoOutput]) {
                if ([self.session canAddOutput:self.photoOutput]) {
                    [self.session addOutput:self.photoOutput];
                } else {
                    if (error == nil) {
                        error = [SKCamera createError:@"Cannot add photoOutput inside the session" code:SKCameraErrorCodeSession];
                    }
                }
            }
        }
        
        
        // add metadata output
        _metadataOutputAdded = NO;
        if (self.faceDetectEnabled) {
            
            if (![self.session.outputs containsObject:self.metadataOutput]) {
                if ([self.session canAddOutput:self.metadataOutput]) {
                    [self.session addOutput:self.metadataOutput];
                    _metadataOutputAdded = YES;
                    
                    /**
                     *  ------->>>>> 注意！！！ metadataOutput 的这个metadataObjectTypes属性，必须在自身被加入到session后，
                     *   即代码[self.session addOutput:self.metadataOutput]后，才能进行设置。
                     *
                     *  否则会出现这个crash: *** Terminating app due to uncaught exception ‘NSInvalidArgumentException’,
                     *  reason: ‘*** -[AVCaptureMetadataOutput setMetadataObjectTypes:] – unsupported type found. Use -availableMetadataObjectTypes.’
                     */
                    [self.metadataOutput setMetadataObjectTypes:[NSArray
                                                                 arrayWithObject:AVMetadataObjectTypeFace]];
                    
                } else {
                    if (error == nil) {
                        error = [SKCamera createError:@"Cannot add metadataOutput inside the sesssion" code:SKCameraErrorCodeSession];
                        [self passError:error];
                    }
                }
            } else {
                _metadataOutputAdded = YES;
            }
        }
        
        //  default whiteBalanceMode
        self.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
    }
    
    // re-enable it
    if (![self.captureVideoPreviewLayer.connection isEnabled]) {
        [self.captureVideoPreviewLayer.connection setEnabled:YES];
    }
    
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}


#pragma mark - Image Capture

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage animationBlock:(void (^)(AVCaptureVideoPreviewLayer *))animationBlock
{
    if(!self.session) {
        NSError *error = [NSError errorWithDomain:SKCameraErrorDomain
                                             code:SKCameraErrorCodeSession
                                         userInfo:nil];
        onCapture(self, nil, nil, error);
        return;
    }
    
    AVCaptureConnection *videoConnection = [self captureConnection];
    videoConnection.videoOrientation = [self orientationForConnection];
    
    BOOL flashActive = self.videoCaptureDevice.flashActive;
    if (!flashActive && animationBlock) {
        animationBlock(self.captureVideoPreviewLayer);
    }
    
    [self.photoOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        UIImage *image = nil;
        NSDictionary *metadata = nil;
        
        if (imageSampleBuffer != NULL) {
            CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
            if(exifAttachments) {
                metadata = (__bridge NSDictionary*)exifAttachments;
            }
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            image = [[UIImage alloc] initWithData:imageData];
            
            if(exactSeenImage) {
                image = [self cropImage:image usingPreviewLayer:self.captureVideoPreviewLayer];
            }
            
            if(self.fixOrientationAfterCapture) {
                image = [image fixOrientation];
            }
        }
        
        if(onCapture) {
            dispatch_async(dispatch_get_main_queue(), ^{
                onCapture(self, image, metadata, error);
            });
        }
    }];
}

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture exactSeenImage:(BOOL)exactSeenImage {
    
    [self capture:onCapture exactSeenImage:exactSeenImage animationBlock:^(AVCaptureVideoPreviewLayer *layer) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration = 0.1;
        animation.autoreverses = YES;
        animation.repeatCount = 0.0;
        animation.fromValue = [NSNumber numberWithFloat:1.0];
        animation.toValue = [NSNumber numberWithFloat:0.1];
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        [layer addAnimation:animation forKey:@"animateOpacity"];
    }];
}

-(void)capture:(void (^)(SKCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error))onCapture
{
    [self capture:onCapture exactSeenImage:NO];
}



#pragma mark - delegates

- (void)setCaptureDelegate:
(id<AVCaptureVideoDataOutputSampleBufferDelegate>)captureDelegate {
    if (_videoOutputEnabled) {
        [self.videoDataOutput setSampleBufferDelegate:captureDelegate queue:_sessionQueue];
    }
}

- (id<AVCaptureVideoDataOutputSampleBufferDelegate>)captureDelegate {
    return [self.videoDataOutput sampleBufferDelegate];
}

- (void)setAudioDelegate:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)audioDelegate
{
    if (_audioOutputEnabled) {
        [self.audioDataOutput setSampleBufferDelegate:audioDelegate queue:_sessionQueue];
    }
}

- (id<AVCaptureAudioDataOutputSampleBufferDelegate>)audioDelegate
{
    return [self.audioDataOutput sampleBufferDelegate];
}

- (void)setFaceDetectionDelegate:
(id<AVCaptureMetadataOutputObjectsDelegate>)faceDetectionDelegate {
    if (_faceDetectEnabled) {
        [self.metadataOutput setMetadataObjectsDelegate:faceDetectionDelegate  queue:_sessionQueue];
    }
}

- (id<AVCaptureMetadataOutputObjectsDelegate>)faceDetectionDelegate {
    return [self.metadataOutput metadataObjectsDelegate];
}


#pragma mark - Video Capture

- (void)startRecordingWithOutputUrl:(NSURL *)url didRecord:(void (^)(SKCamera *camera, NSURL *outputFileUrl, NSError *error))completionBlock
{
    if(!self.videoEnabled) {
        NSError *error = [SKCamera createError:@"Video enables did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    if (!_needRecord) {
        NSError *error = [SKCamera createError:@"needrecord did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    if(self.flash == SKCameraFlashOn) {
        [self enableTorch:YES];
    }
    
    [self.session beginConfiguration];
    if (!_movieFileOutput) {
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        [_movieFileOutput setMovieFragmentInterval:kCMTimeInvalid];
        if([self.session canAddOutput:_movieFileOutput]) {
            [self.session addOutput:_movieFileOutput];
        }
    }
    
    AVCaptureConnection *captureConnection=[_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    // 开启视频防抖模式
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([self.videoDeviceInput.device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [captureConnection setPreferredVideoStabilizationMode:stabilizationMode];
    }
    
    // 预览图层和视频方向保持一致,这个属性设置很重要，如果不设置，那么出来的视频图像可以是倒向左边的。
    captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;
    
    [self.session commitConfiguration];
    
    for(AVCaptureConnection *connection in [self.movieFileOutput connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                if ([connection isVideoOrientationSupported]) {
                    [connection setVideoOrientation:[self orientationForConnection]];
                }
            }
        }
    }
    
    self.didRecordCompletionBlock = completionBlock;
    
    unlink([[url path] UTF8String]);
    
    [self.movieFileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
}



- (void)stopRecording
{
    if(!self.videoEnabled) {
        NSError *error = [SKCamera createError:@"Video enables did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    if (!_needRecord) {
        NSError *error = [SKCamera createError:@"needrecord did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    
    [self.movieFileOutput stopRecording];
}


/*
 * 开始录制视频   (可以设置 录制的 区域)
 *
 * @param url   视频输出的url
 */
- (void)setupRecordingConfigWithOutputUrl:(NSURL *)url  cropFrame:(CGRect)cropFrame didRecord:(void (^)(SKCamera *camera, NSURL *outputFileUrl, NSError *error))completionBlock {

    if(!self.videoEnabled) {
        NSError *error = [SKCamera createError:@"Video enables did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    if (!_needRecord) {
        NSError *error = [SKCamera createError:@"needrecord did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    if(self.flash == SKCameraFlashOn) {
        [self enableTorch:YES];
    }
    
    if (cropFrame.size.width && cropFrame.size.height) {
        _cropFrame = cropFrame;
    } else {
        NSError *error = [SKCamera createError:@"cropFrame.size should not set CGSizeZero" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
    }
    
    self.didRecordCompletionBlock = completionBlock;
    
    unlink([[url path] UTF8String]);
    
    [self createWriter:url cropSize:CGSizeMake(cropFrame.size.width, cropFrame.size.height)];
    
    if(self.onStartRecording) self.onStartRecording(self);

}


- (void)createWriter:(NSURL *)assetUrl  cropSize:(CGSize)cropSize {
    
    self.videoWriter = [AVAssetWriter assetWriterWithURL:assetUrl fileType:AVFileTypeMPEG4 error:nil];
    //使其更适合在网络上播放
    self.videoWriter.shouldOptimizeForNetworkUse = YES;
    
    int videoWidth = cropSize.width;
    int videoHeight =cropSize.height;
    
    
   
    NSDictionary *outputSettings = @{
                                     AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoWidthKey : @(videoHeight),
                                     AVVideoHeightKey : @(videoWidth),
                                     AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                     };
    self.videoAssetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    // 表明输入是否应该调整其处理为实时数据源的数据
    self.videoAssetWriterInput.expectsMediaDataInRealTime = YES;
    self.videoAssetWriterInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    
    NSDictionary *audioOutputSettings = @{
                                          AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                          AVEncoderBitRateKey:@(64000),
                                          AVSampleRateKey:@(44100),
                                          AVNumberOfChannelsKey:@(1),
                                          };
    
    self.audioAssetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    self.audioAssetWriterInput.expectsMediaDataInRealTime = YES;
    
    
    NSDictionary *SPBADictionary = @{
                                     (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (__bridge NSString *)kCVPixelBufferWidthKey : @(videoWidth),
                                     (__bridge NSString *)kCVPixelBufferHeightKey  : @(videoHeight),
                                     (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : ((__bridge NSNumber *)kCFBooleanTrue)
                                     };
    
    
    self.pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoAssetWriterInput sourcePixelBufferAttributes:SPBADictionary];
    
    if ([self.videoWriter canAddInput:self.videoAssetWriterInput]) {
        [self.videoWriter addInput:self.videoAssetWriterInput];
    }else {
        NSLog(@"不能添加视频writer的input \(assetWriterVideoInput)");
    }
    if ([self.videoWriter canAddInput:self.audioAssetWriterInput]) {
        [self.videoWriter addInput:self.audioAssetWriterInput];
    }else {
        NSLog(@"不能添加视频writer的input \(assetWriterVideoInput)");
    }
}


/**
 * 开启录制功能
 */
- (void)sk_enableRecording {
    _startRecordTime = CMTimeMake(0, 0);
    self.recording = NO;
    self.paused = NO;
    self.discont = NO;
    [self startRunnig];
}

/**
 * 关闭录制功能
 */
- (void)sk_shutRecording {
    
    _startRecordTime = CMTimeMake(0, 0);
 
    if ([self.session isRunning]) {
        [self stopRunnig];
    }
}



/**
 * 开始录制视频  (可以设置 录制的 区域)
 */
- (void)sk_startRecording {
    
    @synchronized (self) {
        if (!self.isRecording) {
            self.paused = NO;
            self.discont = NO;
            self.recording = YES;
            _useAssetWriter = YES;
            _timeOffset= CMTimeMake(0, 0);
        }
    }
}


/**
 * 暂停录制视频
 */
- (void)sk_pauseRecording {
    
    @synchronized (self) {
        if (self.isRecording) {
            self.paused = YES;
            self.discont = YES;
        }
    }
}


/**
 * 继续录制视频
 */
- (void)sk_resumeRecording {

    @synchronized (self) {
        if (self.isPaused) {
            self.paused = NO;
        }
    }
}

/**
 * 停止录制视频
 */
- (void)sk_stopRecording {
    
    [self sk_pauseRecording];
    
    @synchronized (self) {
        if (self.isRecording) {
            self.recording = NO;
            _useAssetWriter = NO;

            dispatch_async(_sessionQueue, ^{
                
                if (self.videoWriter) {
                    
                    [self.videoWriter finishWritingWithCompletionHandler:^{
                        NSLog(@"写完了");
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self enableTorch:NO];
                            self.recording = NO;
                            _startRecordTime = CMTimeMake(0, 0);
                            _currentRecordTime = 0;
                            
                            if(self.didRecordCompletionBlock) {
                                self.didRecordCompletionBlock(self, self.videoWriter.outputURL, nil);
                                // self.videoWriter = nil;
                                // self.pixelBufferAdaptor = nil;
                            }
                        });
                    }];
                }
            });
            
        }
    }
}

/**
 * 停止录制视频 (可以设置 录制的 区域)
 */
- (void)stopRectRecording {
    
    if(!self.videoEnabled) {
        NSError *error = [SKCamera createError:@"Video enables did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    
    if (!_needRecord) {
        NSError *error = [SKCamera createError:@"needrecord did not set YES" code:SKCameraErrorCodeVideoNotEnabled];
        [self passError:error];
        return;
    }
    _useAssetWriter = NO;
    self.recording = NO;

    kWeakObj(self)
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"写完了");
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself enableTorch:NO];
            if(self.didRecordCompletionBlock) {
                self.didRecordCompletionBlock(self, self.videoWriter.outputURL, nil);
                self.videoWriter = nil;
                self.pixelBufferAdaptor = nil;
            }
        });
    }];

}


//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    
    /*
     *  OpenGL  渲染 CMSampleBufferRef
     *
    if (captureOutput == self.videoDataOutput) { // video
        [self.openGLView displayWithSampleBuffer:sampleBuffer];
    }
    return;
     
     */
    
    @synchronized (self) {
        
        if (! self.isRecording  || ! _useAssetWriter || self.isPaused) {
            return;
        }
        
        if (self.discont) {
            
            if (captureOutput == self.videoDataOutput) { // video
                return;
            }
            
            self.discont = NO;
            // 计算暂停的时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = (captureOutput == self.videoDataOutput ? _lastVideoTime : _lastAudioTime ) ;
            
            if (last.flags & kCMTimeFlags_Valid) {
                
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                
                CMTime offset = CMTimeSubtract(pts, last);
                
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                } else {
                
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
                
            }
            
            _lastAudioTime.flags = 0;
            _lastAudioTime.flags = 0;
        }
        
        CFRetain(sampleBuffer);
        if (_timeOffset.value  > 0) {
            CFRelease(sampleBuffer);
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];

        }
        
        // 记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime duration = CMSampleBufferGetDuration(sampleBuffer) ;
        
        if (duration.value > 0) {
            pts = CMTimeAdd(pts, duration);
        }
        
        if (captureOutput == self.videoDataOutput) { // video
            _lastVideoTime = pts;
        } else {
            _lastAudioTime = pts;
        }
    }
    
    CMTime duration = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (_startRecordTime.value == 0) {
        _startRecordTime = duration;
    }

    CMTime sub = CMTimeSubtract(duration, _startRecordTime);
    _currentRecordTime = CMTimeGetSeconds(sub);
    
    if (_currentRecordTime > _maxRecordTime) { // 超过最长时间
        if (_currentRecordTime - _maxRecordTime < 0.1) {
            // preogress
        }
        return;
    }
    
    // preogress delegate
    
    
    kWeakObj(self)
    
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        
        @autoreleasepool {
            
            UIImage *originImage = [SKCamera imageFromSampleBuffer:sampleBuffer]; //  {1280, 720}
            
            CGFloat distanceY = originImage.size.height *  _cropFrame.origin.y / [self previewView].size.width;
            
            CGFloat distanceX = originImage.size.width *  _cropFrame.origin.x / [self previewView].size.height;
            
            UIImage *cropImage = [originImage croppedImageWithFrame:CGRectMake(distanceY, distanceX, _cropFrame.size.width , _cropFrame.size.height)];// 横向的图片 cropImage.size = {720, 720}
            
            if (cropImage) {
                
                dispatch_async_on_main_queue(^{
                    
                    NSLog(@"originImage.size = %@",NSStringFromCGSize(originImage.size));
                    NSLog(@"distanceY = %f",distanceY);
                    NSLog(@"cropImage = %@",NSStringFromCGSize(cropImage.size));

                    if (weakself.handleRecording) {
                        weakself.handleRecording(cropImage);
                    }
                });
                
                CVPixelBufferRef pixelBuffer = NULL;
                
                if (self.videoWriter.status == AVAssetWriterStatusUnknown && captureOutput == self.videoDataOutput) {
                    
                    CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    [self.videoWriter startWriting];
                    [self.videoWriter startSessionAtSourceTime:startTime];
                }
                
                if (self.videoWriter.status == AVAssetWriterStatusFailed ) {
                    NSLog(@"writer error %@", self.videoWriter.error.localizedDescription);
                    return;
                }
                
                if (captureOutput == self.videoDataOutput) { // video
                    
                      /*   也可以用
        
                    if (self.videoAssetWriterInput.readyForMoreMediaData == YES) {
                        [self.videoAssetWriterInput appendSampleBuffer:sampleBuffer];
                    }
                     */
                    
                    if (self.pixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData) {
                        
                        pixelBuffer = [SKCamera pixelBufferFromCGImage:cropImage.CGImage];
                        
                        if (self.pixelBufferAdaptor) {
                            
                            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                            
                            BOOL success = [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:startTime];
                            if (!success) {
                                NSLog(@"Pixel Buffer did append fail.");
                            }
                        }
                    }
                    
                } else { // audio
                    if (self.audioAssetWriterInput.readyForMoreMediaData == YES) {
                        [self.audioAssetWriterInput appendSampleBuffer:sampleBuffer];
                        
                    }
                }
                
                CVPixelBufferRelease(pixelBuffer);
                
            }
        }
    }
    
    CFRelease(sampleBuffer);

}


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    self.recording = YES;
    if(self.onStartRecording) self.onStartRecording(self);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    self.recording = NO;
    [self enableTorch:NO];
    
    if(self.didRecordCompletionBlock) {
        self.didRecordCompletionBlock(self, outputFileURL, error);
    }
}

- (void)enableTorch:(BOOL)enabled
{
    if([self isTorchAvailable]) {
        AVCaptureTorchMode torchMode = enabled ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
        NSError *error;
        if ([self.videoCaptureDevice lockForConfiguration:&error]) {
            [self.videoCaptureDevice setTorchMode:torchMode];
            [self.videoCaptureDevice unlockForConfiguration];
        } else {
            [self passError:error];
        }
    }
}

#pragma mark - Helpers


- (SKOpenGLView *)openGLView
{
    if (_openGLView == nil) {
        SKOpenGLView *glView = [[SKOpenGLView alloc] initWithFrame:self.previewView.bounds];
        _openGLView = glView;
        [self.previewView addSubview:_openGLView];
    }
    return _openGLView;
}

- (void)passError:(NSError *)error
{
    if(self.onError) {
        __weak typeof(self) weakSelf = self;
        self.onError(weakSelf, error);
    }
}

- (AVCaptureConnection *)captureConnection
{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.photoOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    return videoConnection;
}


- (void)setVideoCaptureDevice:(AVCaptureDevice *)videoCaptureDevice
{
    _videoCaptureDevice = videoCaptureDevice;
    
    if(videoCaptureDevice.flashMode == AVCaptureFlashModeAuto) {
        _flash = SKCameraFlashAuto;
    } else if(videoCaptureDevice.flashMode == AVCaptureFlashModeOn) {
        _flash = SKCameraFlashOn;
    } else if(videoCaptureDevice.flashMode == AVCaptureFlashModeOff) {
        _flash = SKCameraFlashOff;
    } else {
        _flash = SKCameraFlashOff;
    }
    
    _effectiveScale = 1.0f;
    
    if(self.onDeviceChange) {
        __weak typeof(self) weakSelf = self;
        self.onDeviceChange(weakSelf, videoCaptureDevice);
    }
}

- (BOOL)isFlashAvailable
{
    return self.videoCaptureDevice.hasFlash && self.videoCaptureDevice.isFlashAvailable;
}

- (BOOL)isTorchAvailable
{
    return self.videoCaptureDevice.hasTorch && self.videoCaptureDevice.isTorchAvailable;
}


- (BOOL)updateFlashMode:(SKCameraFlash)cameraFlash
{
    if(!self.session)
        return NO;
    
    AVCaptureFlashMode flashMode;
    
    if(cameraFlash == SKCameraFlashOn) {
        flashMode = AVCaptureFlashModeOn;
    } else if(cameraFlash == SKCameraFlashAuto) {
        flashMode = AVCaptureFlashModeAuto;
    } else {
        flashMode = AVCaptureFlashModeOff;
    }
    
    if([self.videoCaptureDevice isFlashModeSupported:flashMode]) {
        NSError *error;
        if([self.videoCaptureDevice lockForConfiguration:&error]) {
            self.videoCaptureDevice.flashMode = flashMode;
            [self.videoCaptureDevice unlockForConfiguration];
            
            _flash = cameraFlash;
            return YES;
        } else {
            [self passError:error];
            return NO;
        }
    }
    else {
        return NO;
    }
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode
{
    if ([self.videoCaptureDevice isWhiteBalanceModeSupported:whiteBalanceMode]) {
        NSError *error;
        if ([self.videoCaptureDevice lockForConfiguration:&error]) {
            [self.videoCaptureDevice setWhiteBalanceMode:whiteBalanceMode];
            [self.videoCaptureDevice unlockForConfiguration];
        } else {
            [self passError:error];
        }
    }
}

- (void)setMirror:(SKCameraMirror)mirror
{
    _mirror = mirror;
    
    if(!self.session) {
        return;
    }
    
//    if (!_movieFileOutput) {
//        _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
//        [_movieFileOutput setMovieFragmentInterval:kCMTimeInvalid];
//    }
    
//    for(AVCaptureConnection *connection in [self.videoDataOutput connections]) {
//        for (AVCaptureInputPort *port in [connection inputPorts]) {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
//                if ([connection isVideoOrientationSupported]) {
//                    [connection setVideoOrientation:[self orientationForConnection]];
//                }
//            }
//        }
//    }

    AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureConnection *pictureConnection = [_photoOutput connectionWithMediaType:AVMediaTypeVideo];
    
//    if ([videoConnection isVideoOrientationSupported]) {
//        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
//    }
    
    switch (mirror) {
        case SKCameraMirrorOff: {
            if ([videoConnection isVideoMirroringSupported]) {
                [videoConnection setVideoMirrored:NO];
            }
            
            if ([pictureConnection isVideoMirroringSupported]) {
                [pictureConnection setVideoMirrored:NO];
            }
            break;
        }
            
        case SKCameraMirrorOn: {
            if ([videoConnection isVideoMirroringSupported]) {
                [videoConnection setVideoMirrored:YES];
            }
            
            if ([pictureConnection isVideoMirroringSupported]) {
                [pictureConnection setVideoMirrored:YES];
            }
            break;
        }
            
        case SKCameraMirrorAuto: {
            BOOL shouldMirror = (_position == SKCameraPosition_Front);
            if ([videoConnection isVideoMirroringSupported]) {
                [videoConnection setVideoMirrored:shouldMirror];
            }
            
            if ([pictureConnection isVideoMirroringSupported]) {
                [pictureConnection setVideoMirrored:shouldMirror];
            }
            break;
        }
    }
    
    return;
}

- (SKCameraPosition)togglePosition
{
    if(!self.session) {
        return self.position;
    }
    
    if(self.position == SKCameraPosition_Back) {
        self.cameraPosition = SKCameraPosition_Front;
    } else {
        self.cameraPosition = SKCameraPosition_Back;
    }
    
    return self.position;
}

- (void)setCameraPosition:(SKCameraPosition)cameraPosition
{
    if(_position == cameraPosition || !self.session) {
        return;
    }
    
    if(cameraPosition == SKCameraPosition_Back && ![self.class isRearCameraAvailable]) {
        return;
    }
    
    if(cameraPosition == SKCameraPosition_Front && ![self.class isFrontCameraAvailable]) {
        return;
    }
    
    [self.session beginConfiguration];
    
    // 1. remove existing input
    [self.session removeInput:self.audioDeviceInput]; // fix AURemoteIO Thread
    
    [self.session removeInput:self.videoDeviceInput];
    
    // 2. get new input
    AVCaptureDevice *device = nil;
    if(self.videoDeviceInput.device.position == AVCaptureDevicePositionBack) {
        device = [self cameraWithPosition:AVCaptureDevicePositionFront];
    } else {
        device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    
    if(!device) {
        return;
    }
    
    // 3.add input to session
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if(error) {
        [self passError:error];
        [self.session commitConfiguration];
        return;
    }
    
    _position = cameraPosition;
    
    [self.session addInput:videoInput];
    [self.session commitConfiguration];
    
    self.videoCaptureDevice = device;
    self.videoDeviceInput = videoInput;
    
    [self setMirror:_mirror];
}


- (AVCaptureConnection*)videoConnection {
    for (AVCaptureConnection * connection in self.videoDataOutput.connections) {
        for (AVCaptureInputPort * port in connection.inputPorts) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                return connection;
            }
        }
    }
    
    return nil;
}


- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) return device;
    }
    return nil;
}

#pragma mark - Focus

- (void)previewTapped:(UIGestureRecognizer *)gestureRecognizer
{
    if(!self.tapToFocus) {
        return;
    }
    
    CGPoint touchedPoint = [gestureRecognizer locationInView:self.previewView];
    CGPoint pointOfInterest = [self convertToPointOfInterestFromViewCoordinates:touchedPoint
                                                                   previewLayer:self.captureVideoPreviewLayer
                                                                          ports:self.videoDeviceInput.ports];
    [self focusAtPoint:pointOfInterest];
    [self showFocusBox:touchedPoint];
}

- (void)addDefaultFocusBox
{
    CALayer *focusBox = [[CALayer alloc] init];
    focusBox.cornerRadius = 5.0f;
    focusBox.bounds = CGRectMake(0.0f, 0.0f, 70, 60);
    focusBox.borderWidth = 3.0f;
    focusBox.borderColor = [[UIColor yellowColor] CGColor];
    focusBox.opacity = 0.0f;
    [self.previewView.layer addSublayer:focusBox]; // new add
    
    CABasicAnimation *focusBoxAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    focusBoxAnimation.duration = 0.75;
    focusBoxAnimation.autoreverses = NO;
    focusBoxAnimation.repeatCount = 0.0;
    focusBoxAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    focusBoxAnimation.toValue = [NSNumber numberWithFloat:0.0];
    
    [self alterFocusBox:focusBox animation:focusBoxAnimation];
}

- (void)alterFocusBox:(CALayer *)layer animation:(CAAnimation *)animation
{
    self.focusBoxLayer = layer;
    self.focusBoxAnimation = animation;
}

- (void)focusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = self.videoCaptureDevice;
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        } else {
            [self passError:error];
        }
    }
}

- (void)showFocusBox:(CGPoint)point
{
    if(self.focusBoxLayer) {
        // clear animations
        [self.focusBoxLayer removeAllAnimations];
        
        // move layer to the touch point
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        self.focusBoxLayer.position = point;
        [CATransaction commit];
    }
    
    if(self.focusBoxAnimation) {
        // run the animation
        [self.focusBoxLayer addAnimation:self.focusBoxAnimation forKey:@"animateOpacity"];
    }
}


#pragma mark - setter / getter

- (UIView*)previewView {
    return _previewView;
}

- (void)setPreviewView:(UIView *)previewView {
    
    _previewView = previewView;
    
    [self addCustomGesture];
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    
    if (!_videoDataOutput) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES; // 指定接收器是否应始终丢弃在捕获下一帧之前未处理的任何视频帧。
        _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}; // DEFAULT kCVPixelFormatType_32BGRA  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        [_videoDataOutput setSampleBufferDelegate:self.delegate queue:_sessionQueue];
    }
    return _videoDataOutput;
}

- (AVCaptureAudioDataOutput *)audioDataOutput {
    
    if (!_audioDataOutput) {
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioDataOutput setSampleBufferDelegate:self.delegate queue:_sessionQueue];
    }
    return _audioDataOutput;
}

- (AVCaptureStillImageOutput *)photoOutput {
    
    if (!_photoOutput) {
        _photoOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [_photoOutput setOutputSettings:outputSettings];
    }
    return _photoOutput;
}

- (AVCaptureMetadataOutput *)metadataOutput {
    
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_metadataOutput setMetadataObjectsDelegate:self.delegate  queue:_sessionQueue];
        
    }
    return _metadataOutput;
}


- (void)previewViewFrameChanged {
    _captureVideoPreviewLayer.affineTransform = CGAffineTransformIdentity;
    _captureVideoPreviewLayer.frame = _previewView.bounds;
    
    CGRect bounds = self.previewView.bounds;
    self.captureVideoPreviewLayer.bounds = bounds;
    self.captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    self.captureVideoPreviewLayer.connection.videoOrientation = [self orientationForConnection];
    
}

- (void)setCameraQuality:(NSString *)cameraQuality {
    
    if (cameraQuality != nil && cameraQuality.length > 0) {
        _cameraQuality = cameraQuality;
        if ([cameraQuality isEqualToString:AVCaptureSessionPreset640x480]) {
            _imageSize = CGSizeMake(640, 480);
        } else if ([cameraQuality isEqualToString:AVCaptureSessionPreset1920x1080]) {
            _imageSize = CGSizeMake(1920, 1080);
        } else if ([cameraQuality isEqualToString:AVCaptureSessionPreset1280x720]) {
            _imageSize = CGSizeMake(1280, 720);
        }
    }
}

- (void)setNeedRecord:(BOOL)needRecord {
    _needRecord = needRecord;
}


- (AVCaptureVideoOrientation)orientationForConnection
{
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    
    if(self.useDeviceOrientation) {
        switch ([UIDevice currentDevice].orientation) {
            case UIDeviceOrientationLandscapeLeft:
                videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            default:
                videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
        }
    }
    else {
        switch ([[UIApplication sharedApplication] statusBarOrientation]) {
            case UIInterfaceOrientationLandscapeLeft:
                videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            case UIInterfaceOrientationLandscapeRight:
                videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            default:
                videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
        }
    }
    
    return videoOrientation;
}

- (void)dealloc {
    [self stopRunnig];
    self.session = nil;

}

#pragma mark - Class Methods

+ (void)requestCameraPermission:(void (^)(BOOL granted))completionBlock
{
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock) {
                    completionBlock(granted);
                }
            });
        }];
    } else {
        completionBlock(YES);
    }
}

+ (void)requestMicrophonePermission:(void (^)(BOOL granted))completionBlock
{
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock) {
                    completionBlock(granted);
                }
            });
        }];
    }
}

+ (BOOL)isFrontCameraAvailable
{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

+ (BOOL)isRearCameraAvailable
{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

@end
