//
//  SKOpenGLView.m
//  SKCameraDemo
//
//  Created by KUN on 17/6/28.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "SKOpenGLView.h"
#import <GLKit/GLKit.h>
/* ===========================================opengl 渲染的流程
 01-自定义图层类型
 02-初始化CAEAGLLayer图层属性
 03-创建EAGLContext
 04-创建渲染缓冲区
 05-创建帧缓冲区
 06-创建着色器
 07-创建着色器程序
 08-创建纹理对象
 09-YUA转RGB绘制纹理
 10-渲染缓冲区到屏幕
 11-清理内存
 */
// ===========================================================================================//
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

enum{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD
};

// 顶点着色器代码
NSString *const kVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
 }
 );

// 片段着色器代码
NSString *const kYUVFullRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 precision mediump float;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

static const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};
// ===========================================================================================//


@interface SKOpenGLView ()

@property (nonatomic, strong) EAGLContext *eaglContext; //画布
@property (nonatomic, assign) GLsizei bufferWidth; //宽
@property (nonatomic, assign) GLsizei bufferHeight; //高

@property (nonatomic, assign) GLuint framebuffer; //帧缓冲区
@property (nonatomic, assign) GLuint colorRenderbuffer; //渲染缓冲区
@property (nonatomic, assign) GLuint vertexShader; //顶点着色器   //理解为 负责画出图形 框架
@property (nonatomic, assign) GLuint fragmentShader; //片段着色器 //颜色 深度等 理解为画出什么样子的
@property (nonatomic, assign) GLuint program; //着色器程序

@property (nonatomic, assign) CVOpenGLESTextureCacheRef textureCacheRef; //纹理缓存


@property (nonatomic, assign) CVOpenGLESTextureRef luminanceTextureRef; // Y引用  亮度
@property (nonatomic, assign) CVOpenGLESTextureRef chrominanceTextureRef;// UV引用 色度
@property (nonatomic, assign) GLuint luminanceTexture; // Y
@property (nonatomic, assign) GLuint chrominanceTexture; // UV


@property (nonatomic, assign) int luminanceTextureAtt;  //亮度纹理  索引  对应片段着色器 luminanceTexture
@property (nonatomic, assign) int chrominanceTextureAtt; //色度纹理  索引   对应片段着色器 chrominanceTexture
@property (nonatomic, assign) int colorConversionMatrixAtt; //转换纹理 索引 对应片段着色器 colorConversionMatrix

@property (nonatomic, assign)  GLfloat *preferredConversion; //矩阵转换用
@end


@implementation SKOpenGLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

#pragma mark - 初始化OpenGLView
- (void)setup
{
    // 1.设置图层属性
    [self setupLayer];
    
    // 2.创建openGL上下文
    [self setupOpenGLContext];
    
    // 3.创建渲染缓冲区
    [self setupRenderBuffer];
    
    // 4.创建帧缓冲区
    [self setupFrameBuffer];
    
    // 5.创建着色器
    [self setupShader];
    
    // 6.创建着色器程序
    [self setupProgram];
    
    // 创建纹理缓存
    // cacheOut: 指向创建好的纹理缓存
    CVReturn err =CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _eaglContext, NULL, &_textureCacheRef);
    if (err) {
        NSLog(@"CVOpenGLESTextureCacheCreate %d",err);
    }
    _preferredConversion = (GLfloat *)kColorConversion601FullRange;
    
}

#pragma mark -创建着色器程序
- (void)setupProgram
{
    // 创建着色器程序
    _program = glCreateProgram();
    
    // 添加着色器,着色器运行哪些着色器代码
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "inputTextureCoordinate");
    
    // 链接程序
    glLinkProgram(_program);
    
    // 获取全局参数,注意一定要在连接完成后才行，否则拿不到
    _luminanceTextureAtt = glGetUniformLocation(_program, "luminanceTexture");
    _chrominanceTextureAtt = glGetUniformLocation(_program, "chrominanceTexture");
    _colorConversionMatrixAtt = glGetUniformLocation(_program, "colorConversionMatrix");
    
    // 启动程序
    glUseProgram(_program);
    
}

#pragma mark - 创建着色器
- (void)setupShader
{
    // 创建顶点着色器(VERTEX顶点)
    _vertexShader = [self loadShader:GL_VERTEX_SHADER withString:kVertexShaderString];
    
    // 创建片段着色器(FRAGMENT片段)
    _fragmentShader = [self loadShader:GL_FRAGMENT_SHADER withString:kYUVFullRangeConversionForLAFragmentShaderString];
}

#pragma mark - 加载着色器
- (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderCoder
{
    // 1.创建着色器(小程序)
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        NSLog(@"Error: failed to create shader.");
        return 0;
    }
    
    // 2.加载着色器代码
    const char *string = [shaderCoder UTF8String];
    glShaderSource(shader, 1, &string, NULL);
    // 编译着色器代码
    glCompileShader(shader);
    // 判断是否编译完成
    GLint compiled = 0;
    // 获取编译完成状态
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if (compiled == 0) {
        // 编译失败
        glDeleteShader(shader);
        
        return 0;
    }
    
    return shader;
    
}

#pragma mark - 创建帧缓冲区
- (void)setupFrameBuffer
{
    // 生成帧缓存区
    glGenFramebuffers(1, &_framebuffer);
    // 绑定帧缓存区
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    // 把渲染缓存区添加到帧缓存区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
}

#pragma mark- 四.创建渲染缓冲区
- (void)setupRenderBuffer
{
    // 创建渲染缓冲区
    glGenRenderbuffers(1, &_colorRenderbuffer);
    // 绑定缓存区
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    // 分配内存
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
}

#pragma mark- 三.初始化图层属性
- (void)setupOpenGLContext
{
    // 创建OpenGL上下文
    EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _eaglContext = eaglContext;
    
    // 以后所有的绘制 都会绘制到这个上下文中
    [EAGLContext setCurrentContext:_eaglContext];
    
}

#pragma mark- 二.初始化图层属性
- (void)setupLayer
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    
    // GPUImage内部设置
    // kEAGLDrawablePropertyColorFormat:使用RGB格式绘制内容到图层上
    // kEAGLDrawablePropertyRetainedBacking:不保存之前绘制的内容
    eaglLayer.drawableProperties = @{
                                     kEAGLDrawablePropertyRetainedBacking:@(NO),
                                     kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
                                     };
}



// YUA 转 RGB，里面的顶点和片段都要转换
- (void)convertYUVToRGBOutput
{
    // 在创建纹理之前，有激活过纹理单元，就是那个数字.GL_TEXTURE0,GL_TEXTURE1
    // 指定着色器中亮度纹理对应哪一层纹理单元
    // 这样就会把亮度纹理，往着色器上贴
    glUniform1i(_luminanceTextureAtt, 0);
    
    // 指定着色器中色度纹理对应哪一层纹理单元
    glUniform1i(_chrominanceTextureAtt, 1);
    
    // YUA转RGB矩阵
    glUniformMatrix3fv(_colorConversionMatrixAtt, 1, GL_FALSE, _preferredConversion);
    
    // 计算顶点数据结构
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(self.bounds.size.width, self.bounds.size.height), self.layer.bounds);
    
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/self.layer.bounds.size.width, vertexSamplingRect.size.height/self.layer.bounds.size.height);
    
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
    }
    
    // 确定顶点数据结构
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
        normalizedSamplingSize.width, normalizedSamplingSize.height,
    };
    
    // 确定纹理数据结构
    GLfloat quadTextureData[] =  { // 正常坐标
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    // 激活ATTRIB_POSITION顶点数组
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    // 给ATTRIB_POSITION顶点数组赋值
    
    //    glVertexAttribPointer(<#GLuint indx#>, <#GLint size#>, <#GLenum type#>, <#GLboolean normalized#>, <#GLsizei stride#>, <#const GLvoid *ptr#>)
    
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
    
    // 激活ATTRIB_TEXCOORD顶点数组
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
    // 给ATTRIB_TEXCOORD顶点数组赋值
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    // 渲染纹理数据数据
    // 把着色器上纹理渲染到 渲染缓存区
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


#pragma mark - 每次获取帧数据,展示到OpenGLView
- (void)displayWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if ([EAGLContext currentContext] != _eaglContext) {
        
        [EAGLContext setCurrentContext:_eaglContext];
    }
    
    // 清空之前的纹理，要不然每次都创建新的纹理，耗费资源，造成界面卡顿
    [self cleanUpTextures];
    
    // 亮度和色度要放在一起
    [self setupTexture:sampleBuffer];
    
    
    // YUV 转 RGB
    [self convertYUVToRGBOutput];
    
    // 渲染
    // 设置窗口尺寸,表示渲染多大屏幕
    glViewport(0,0, self.bounds.size.width, self.bounds.size.height);
    
    // 把上下文的东西渲染到屏幕上
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    
}


- (void)cleanUpTextures
{
    // 清空亮度引用
    if (_luminanceTextureRef) {
        CFRelease(_luminanceTextureRef);
        _luminanceTextureRef = NULL;
    }
    
    // 清空色度引用
    if (_chrominanceTextureRef) {
        CFRelease(_chrominanceTextureRef);
        _chrominanceTextureRef = NULL;
    }
    
    // 清空纹理缓存
    CVOpenGLESTextureCacheFlush(_textureCacheRef, 0);
}

#pragma mark - 销毁渲染和帧缓存
- (void)destoryRenderAndFrameBuffer
{
    glDeleteRenderbuffers(1, &_colorRenderbuffer);
    _colorRenderbuffer = 0;
    
    glDeleteBuffers(1, &_framebuffer);
    _framebuffer = 0;
}

- (void)dealloc
{
    // 清空缓存
    [self destoryRenderAndFrameBuffer];
    
    // 清空纹理
    [self cleanUpTextures];
}


#pragma mark - 7、创建纹理对象，渲染采集图片到屏幕
- (void)setupTexture:(CMSampleBufferRef)sampleBuffer
{
    // 创建纹理缓存对象
    CVImageBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 获取图片宽度
    GLsizei bufferWidth = (GLsizei)CVPixelBufferGetWidth(imageBufferRef);
    _bufferWidth = bufferWidth;
    GLsizei bufferHeight = (GLsizei)CVPixelBufferGetHeight(imageBufferRef);
    _bufferHeight = bufferHeight;
    
    // 创建亮度纹理
    // 激活纹理单元0, 不激活，创建纹理会失败
    glActiveTexture(GL_TEXTURE0);
    
    // 创建纹理对象
    CVReturn err;
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCacheRef, imageBufferRef, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &_luminanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    // 获取纹理对象
    _luminanceTexture = CVOpenGLESTextureGetName(_luminanceTextureRef);
    
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, _luminanceTexture);
    
    // 设置纹理滤波
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 激活单元1
    glActiveTexture(GL_TEXTURE1);
    
    // 创建色度纹理
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCacheRef, imageBufferRef, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth / 2, bufferHeight / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &_chrominanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    // 获取纹理对象
    _chrominanceTexture = CVOpenGLESTextureGetName(_chrominanceTextureRef);
    
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
    
    // 设置纹理滤波
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}


@end
