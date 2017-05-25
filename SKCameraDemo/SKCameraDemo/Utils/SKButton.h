//
//  SKButton.h
//  SKCameraDemo
//
//  Created by KUN on 17/5/25.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKButton : UIButton

@property (nonatomic , copy) void(^clickAction)(UIButton *btn);

@end

@interface UIButton (Factory)

// image button & Block
+ (UIButton *)createImgButtonWithFrame:(CGRect)frame
                             imageName:(NSString *)imageName
                           clickAction:(void(^)(UIButton *btn))clickAction;

// title button & Block
+ (UIButton *)createTitleButtonWithFrame:(CGRect)frame
                                   title:(NSString *)title
                              titleColor:(UIColor *)titleColor
                               titleFont:(UIFont *)titleFont
                           clickAction:(void(^)(UIButton *btn))clickAction;


// image button & SEL
+ (UIButton *) buttonWithImage:(NSString *)imageName
                 highlighImage:(NSString *)hightlighImageName
                   selectImage:(NSString *)selectImageName
                     addTarget:(id)target
                        action:(SEL)action;
// title button & SEL
+ (UIButton *) buttonWithTitle:(NSString *)buttonTitle
                    titleColor:(UIColor *)titleColor
                     titleFont:(UIFont *)titleFont
                     addTarget:(id)target
                        action:(SEL)action;

// image & title
+ (UIButton *) buttonWithTitle:(NSString *)buttonTitle
                    titleColor:(UIColor *)titleColor
                     titleFont:(UIFont *)titleFont
                         image:(NSString *)imageName
                 highlighImage:(NSString *)hightlighImageName
                   selectImage:(NSString *)selectImageName
                     addTarget:(id)target
                        action:(SEL)action;
@end
