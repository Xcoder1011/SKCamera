//
//  SKCameraWriter.m
//  SKCameraDemo
//
//  Created by KUN on 17/6/16.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "SKCameraWriter.h"

@interface SKCameraWriter ()
{

    CMTime _currentSampleTime;
}

@property (nonatomic, strong) AVAssetWriter *videoWriter;

@property (nonatomic, strong) AVAssetWriterInput *videoAssetWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioAssetWriterInput;

@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;  //缓冲区

@property (nonatomic, assign) CMSampleBufferRef currentbuffer;

@property (nonatomic, assign) CGSize cropSize;

@property (nonatomic, strong) NSURL*  myRecordURL;

@property (nonatomic, strong) dispatch_queue_t writeQueue;


@end

@implementation SKCameraWriter

- (instancetype)init {
    
    if (self = [super init]) {
        
      _cropSize = [UIScreen mainScreen].bounds.size;
    }
    return self;
    
}


- (void)setCropSize:(CGSize)size {
    
    _cropSize = size;
}

- (void)setRecordingURL:(NSURL *)recordingURL {

    _recordingURL = recordingURL;
    _writeQueue = dispatch_queue_create("com.SKCameraWriter.writeQueue", DISPATCH_QUEUE_SERIAL);

}


- (void)prepareRecording {
    
    NSError *error = nil;
    
    unlink([[_recordingURL path] UTF8String]);

    self.videoWriter = [AVAssetWriter assetWriterWithURL:_recordingURL fileType:AVFileTypeMPEG4 error:nil];
    
    NSParameterAssert(self.videoWriter);
    
    if(error) NSLog(@"error = %@", [error localizedDescription]);
    
    
    if (_cropSize.height == 0 || _cropSize.width == 0) {
        _cropSize = [UIScreen mainScreen].bounds.size;
    }
    
    
    NSString *width = [NSString stringWithFormat:@"%f",_cropSize.width];
    
    NSAssert(!([width integerValue] % 320), @" 注意: videoWidth 必须设置为 320的整数倍!");
    
    /*
     *  注意: videoWidth 必须设置为 320的整数倍， 否则生成的视频 右边会有 一条蓝色的细线 !!!!!!!!!!!!!!
     */
    int videoWidth = _cropSize.width;
    int videoHeight =_cropSize.height;
    
 
    NSDictionary *outputSettings = @{
                                     AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoWidthKey : @(videoHeight),
                                     AVVideoHeightKey : @(videoWidth),
                                     AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                     };

    
    self.videoAssetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    self.videoAssetWriterInput.expectsMediaDataInRealTime = YES;
    /*
     *  注意: AVVideoWidthKey 和 AVVideoHeightKey 如果 不进行旋转 90度的话， 参数和我们设置的应当相反
     */
    self.videoAssetWriterInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);

    
    
    // 缓冲区参数设置
    NSDictionary *sourcePixelBufferAttributesDictionary = @{
                                                            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                                            (__bridge NSString *)kCVPixelBufferWidthKey : @(videoWidth),
                                                            (__bridge NSString *)kCVPixelBufferHeightKey  : @(videoHeight),
                                                            (__bridge NSString *)kCVPixelFormatOpenGLESCompatibility : ((__bridge NSNumber *)kCFBooleanTrue)
                                                            };
    
    self.pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoAssetWriterInput
                    
                                                                                    sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(self.videoAssetWriterInput);
    NSParameterAssert([self.videoWriter canAddInput:self.videoAssetWriterInput]);
    
    //添加音频输入
//    AudioChannelLayout acl;
//    bzero( &acl, sizeof(acl));
//    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
//    //音频配置
//    NSDictionary* audioOutputSettings = nil;
//    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
//                           
//                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
//                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
//                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
//                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
//                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
//                           nil ];
    
    NSDictionary *audioOutputSettings = @{
                                          AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                          AVEncoderBitRateKey:@(64000),
                                          AVSampleRateKey:@(44100),
                                          AVNumberOfChannelsKey:@(1),
                                          };
    
    self.audioAssetWriterInput = [AVAssetWriterInput  assetWriterInputWithMediaType: AVMediaTypeAudio
                                                          outputSettings: audioOutputSettings];
    self.audioAssetWriterInput.expectsMediaDataInRealTime = YES;
    
    // 图像和语音输入添加到刻录机
    
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
    
    if([self.delegate respondsToSelector:@selector(videoWriterDidStartRecording:)]){
        
        [self.delegate videoWriterDidStartRecording:self];
    }

}

- (void)finishRecording {
    
    
    __weak __typeof(self)weakSelf = self;
    
    if(_videoWriter && _videoWriter.status == AVAssetWriterStatusWriting){
        
        dispatch_async(self.writeQueue, ^{
            
            [self.videoAssetWriterInput markAsFinished];
            
            [self.audioAssetWriterInput markAsFinished];
            
            [self.videoWriter cancelWriting];

            [self.videoWriter finishWritingWithCompletionHandler:^{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if([weakSelf.delegate respondsToSelector:@selector(videoWriterDidFinishRecording:outputUrl:)]){
                        
                        [weakSelf.delegate videoWriterDidFinishRecording:weakSelf outputUrl:weakSelf.recordingURL];
                    }
                });
            }];
            
        });
    }
}


- (void)cancleRecording {
    
    [self finishRecording];
}


- (BOOL)writeVideoSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    
    if (self.videoWriter.status == AVAssetWriterStatusUnknown) {
        [self.videoWriter startWriting];
        [self.videoWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    }
    if (self.videoWriter.status == AVAssetWriterStatusFailed) {
        //TODO log error
        return NO;
    }
    if (self.videoAssetWriterInput.readyForMoreMediaData) {
        [self.videoAssetWriterInput appendSampleBuffer:sampleBuffer];
    }
    if (self.audioAssetWriterInput.readyForMoreMediaData) {
        [self.audioAssetWriterInput appendSampleBuffer:sampleBuffer];
    }
    return YES;
}



- (void)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    if (_videoWriter.status != AVAssetWriterStatusWriting) {
        [_videoWriter startWriting];
        [_videoWriter startSessionAtSourceTime:_currentSampleTime];
    }
    
    @synchronized(self){
        
        if (self.videoAssetWriterInput.isReadyForMoreMediaData) {

            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            BOOL success = [_pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:_currentSampleTime];
            if (!success) {
                NSLog(@"Pixel Buffer没有append成功");
                [self finishRecording];
            }
        }
    }
}



- (void)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    
//    _currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
//    if (_videoWriter.status != AVAssetWriterStatusWriting) {
//        [_videoWriter startWriting];
//        [_videoWriter startSessionAtSourceTime:_currentSampleTime];
//    }
    
    BOOL success = [_audioAssetWriterInput appendSampleBuffer:sampleBuffer];
    if (!success) {
        NSLog(@"Adio Pixel Buffer 没有append成功");
        [self finishRecording];
    }
}

- (void)destroyWrite
{
    self.videoWriter = nil;
    self.audioAssetWriterInput = nil;
    self.videoAssetWriterInput = nil;
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    [self destroyWrite];
}

@end
