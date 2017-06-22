//
//  SKCameraWriter.h
//  SKCameraDemo
//
//  Created by KUN on 17/6/16.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  刻录机 ------>>>>> 用于导出自定义Rect的Video
 */

@class SKCameraWriter;
@protocol SKCameraWriterDelegate <NSObject>

- (void)videoWriterDidStartRecording:(SKCameraWriter *)writer ;

- (void)videoWriterDidFinishRecording:(SKCameraWriter *)writer outputUrl:(NSURL *)outputUrl;

@end


@interface SKCameraWriter : NSObject

@property (nonatomic, strong) NSURL *recordingURL;

- (void)setCropSize:(CGSize)size;


@property (nonatomic, weak) id <SKCameraWriterDelegate> delegate;

- (void)prepareRecording;

- (void)finishRecording;//正常结束
- (void)cancleRecording;//取消录制

- (void)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer;

@end
