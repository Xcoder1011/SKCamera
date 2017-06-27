//
//  UIImage+Utils.h
//  SKCamera
//
//  Created by KUN on 17/1/13.
//  Copyright © 2017年 NULL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

- (UIImage *)fixOrientation;

- (UIImage *)croppedImageWithFrame:(CGRect)frame;


/**
 *  裁剪图片
 注：若裁剪范围超出原图尺寸，则会用背景色填充缺失部位
 *
 *  @param Point     坐标
 *  @param Size      大小
 *  @param backColor 背景色
 *
 *  @return 新生成的图片
 */
-(UIImage *)croppedImageAtPoint:(CGPoint)Point
                       withSize:(CGSize)Size
                backgroundColor:(UIColor *)backColor;


/**
 *  旋转图片
 *
 *  @param Angle 角度（0~360）
 */
- (UIImage *)rotationAngle:(CGFloat)Angle ;
@end
