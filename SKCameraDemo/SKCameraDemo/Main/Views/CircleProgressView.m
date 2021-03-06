//
//  CircleProgressView.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/22.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "CircleProgressView.h"
#import "CALayer+ControlAnimation.h"

#define PROGRESSW self.frame.size.width
#define PROGRESSH self.frame.size.height
//Degress to PI
#define SKDegreesToRadians(x) (M_PI*(x)/180.0)

//Defalut value
#define SKTotalTime               (100)
#define SKProgressLineWidth       (kscaleDeviceWidth(12))
#define SKProgressLineColor       [UIColor whiteColor]

@interface CircleProgressView () <CAAnimationDelegate>
{
    BOOL _isAnimating;
    BOOL _isResumeAnimation;  // 是否是继续录制事件
}

@property (nonatomic, strong) CALayer *middleLayer;
@property (nonatomic, strong) CALayer *bgLayer;
@property (strong, nonatomic) CAShapeLayer * progressLayer;   // circle progress
@property (strong, nonatomic) CAShapeLayer * checkmarkLayer;  // 对号✅

@property (nonatomic, strong) UIButton *tapButton;

@property (strong, nonatomic) CAAnimationGroup *animationGroup;
@property (strong, nonatomic) CABasicAnimation *strokeAnimationEnd;

@end


static float const ANIMATION_DURATION = 0.5; // duration

static inline CABasicAnimation* ScaleAnimation(CGFloat fromValue, CGFloat toValue,float duration) {
    
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    anima.fromValue = [NSNumber numberWithFloat:fromValue];
    anima.toValue = [NSNumber numberWithFloat:toValue];
    anima.duration = duration;
    anima.fillMode = kCAFillModeForwards;
    anima.removedOnCompletion = NO;
    return anima;
}

@implementation CircleProgressView

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self _commonInit];

        [self setSubLayers];
    }
    return self;
}

-(void)_commonInit{
    
    self.progressLineColor = SKProgressLineColor;
    self.progressLineWidth = SKProgressLineWidth;
    self.startAngle = -M_PI * 1.0/2;
    self.endAngle = M_PI * 3.0/2;
    self.totalTime = SKTotalTime;
    self.userInteractionEnabled = YES;
    [self.layer addSublayer:self.progressLayer];
    _isAnimating = NO;
    _isResumeAnimation = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
}



#pragma mark - notification
- (void)applicationEnterBackground
{
    if (_isAnimating) {
        [self.progressLayer pauseLayerCoreAnimation];
        _isAnimating = NO;
    }
}

- (void)applicationDidBecomeActive
{
    if (!_isAnimating) {
        [self.progressLayer resumeLayerCoreAnimation];
        _isAnimating = YES;
    }
}

- (void)setSubLayers {
    
    [self.layer addSublayer:self.bgLayer];
    [self.layer addSublayer:self.middleLayer];
    
    [self addSubview:self.tapButton];
    [self.tapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kscaleDeviceWidth(150));
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
    }];
}

- (void)reset  {

    self.tapButton.selected = NO;
    _isResumeAnimation = NO;
    
    [self stopRunningCircleProgress];
   
}

- (void)tapButtonPressed:(UIButton *)btn {
    
    btn.selected = !btn.selected;
    
    if (btn.selected) {
       
        if (_isResumeAnimation) { // 继续录制
            [self applicationDidBecomeActive];
            
            if (self.clickRecordingBlock) {
                self.clickRecordingBlock(btn);
            }
            return;
        }
        
        // 第一次录制
        [self.middleLayer addAnimation:ScaleAnimation(1.0, 12.0/15, ANIMATION_DURATION) forKey:@"middlelayer"];
        [self.bgLayer addAnimation:ScaleAnimation(1.0, 36.0/24, ANIMATION_DURATION) forKey:@"bgLayer"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (self.clickRecordingBlock) {
                self.clickRecordingBlock(btn);
                [self startRunningCircleProgress];
                _isResumeAnimation = YES;
            }
        });
        
    } else {
        
        [self applicationEnterBackground];
        
        if (self.clickRecordingBlock) {
            self.clickRecordingBlock(btn);
            
        }
    }
}


- (void)startRunningCircleProgress {
    [self.progressLayer addAnimation:self.strokeAnimationEnd forKey:@"group"];
    _isAnimating = YES;
}


- (void)stopRunningCircleProgress{
    
    if (self.strokeAnimationEnd) {
        _isAnimating = NO;
        [self.progressLayer removeAllAnimations];
        [self.middleLayer removeAllAnimations];
        [self.bgLayer removeAllAnimations];
    }
}

/**
 *  动画停止
 *
 *  @param anim CAAnimation对象
 *  @param flag 是否是正常的移除
 */
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

    if (!flag) { // 不正常
        return;
    }
    
    [self stopRunningCircleProgress];
    if (self.stopRecordingVideo) {
        self.stopRecordingVideo(self.tapButton);
    }
}


#pragma  mark - setter

- (void)setProgressLineColor:(UIColor *)progressLineColor {
    _progressLineColor = progressLineColor;
    _progressLayer.strokeColor = self.progressLineColor.CGColor;
}

- (void)setProgressLineWidth:(CGFloat)progressLineWidth {
    _progressLineWidth = progressLineWidth;
    _progressLayer.lineWidth = self.progressLineWidth;
}

#pragma  mark - getter

-(CABasicAnimation *)strokeAnimationEnd
{
    if (!_strokeAnimationEnd) {
        _strokeAnimationEnd = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        _strokeAnimationEnd.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _strokeAnimationEnd.duration = self.totalTime;
        _strokeAnimationEnd.fromValue = @0;
        _strokeAnimationEnd.toValue = @1;
        _strokeAnimationEnd.speed = 1.0;
        _strokeAnimationEnd.fillMode = kCAFillModeForwards;
        _strokeAnimationEnd.delegate = self;
        _strokeAnimationEnd.removedOnCompletion = NO;
    }
    return _strokeAnimationEnd;
}

-(CAAnimationGroup *)animationGroup
{
    if (!_animationGroup) {
        _animationGroup = [CAAnimationGroup animation];
        _animationGroup.animations = @[self.strokeAnimationEnd];
        _animationGroup.duration = self.totalTime;
        _animationGroup.delegate = self;
    }
    return _animationGroup;
}

-(CAShapeLayer *)progressLayer
{
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = CGRectMake(0, 0, PROGRESSW, PROGRESSH);
        _progressLayer.position = CGPointMake(PROGRESSW/2.0, PROGRESSH/2.0);
        _progressLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(PROGRESSW/2.0, PROGRESSH/2.0) radius:(PROGRESSW - self.progressLineWidth)/2.0 startAngle:self.startAngle endAngle: self.endAngle clockwise:YES].CGPath;
        // UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
        // _progressLayer.path = path.CGPath;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineWidth = self.progressLineWidth;
        _progressLayer.strokeColor = self.progressLineColor.CGColor;
        _progressLayer.strokeEnd = 0;
        _progressLayer.strokeStart = 0;
        _progressLayer.lineCap = kCALineCapRound;
    }
    return _progressLayer;
}

- (CALayer *)bgLayer {

    if (!_bgLayer) {
        _bgLayer = [CALayer layer];
        _bgLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
        _bgLayer.bounds = CGRectMake(0, 0, kscaleDeviceWidth(240), kscaleDeviceWidth(240));
        _bgLayer.position = self.center;
        _bgLayer.cornerRadius = kscaleDeviceWidth(240) / 2.0;
        
    }
    return _bgLayer;
}

- (CALayer *)middleLayer {
    
    if (!_middleLayer) {
        _middleLayer = [CALayer layer];
        _middleLayer.backgroundColor = [UIColor whiteColor].CGColor;
        _middleLayer.bounds = CGRectMake(0, 0, kscaleDeviceWidth(150), kscaleDeviceWidth(150));
        _middleLayer.position = self.center;
        _middleLayer.cornerRadius = kscaleDeviceWidth(150) / 2.0;
        
    }
    return _middleLayer;
}

- (UIButton *)tapButton {

    if (!_tapButton) {
        _tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _tapButton.frame = CGRectZero;
        _tapButton.tintColor = [UIColor clearColor];
        [_tapButton addTarget:self action:@selector(tapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _tapButton;
}


-(void)layoutSubviews{
    [super layoutSubviews];
    _progressLayer.frame=self.bounds;
    [self setProgressLineWidth:_progressLineWidth];
}


-(void)dealloc{
    self.strokeAnimationEnd.delegate = nil;
    self.strokeAnimationEnd = nil;
    self.progressLayer = nil;
    self.bgLayer = nil;
    self.middleLayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
