//
//  SKButton.m
//  SKCameraDemo
//
//  Created by KUN on 17/5/25.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import "SKButton.h"

@implementation SKButton

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)clickButton:(UIButton *)btn {

    if (self.clickAction) {
        self.clickAction(btn);
    }
}
@end


@implementation UIButton (Factory)

+ (UIButton *)createImgButtonWithFrame:(CGRect)frame
                             imageName:(NSString *)imageName
                           clickAction:(void(^)(UIButton *btn))clickAction {
    
    SKButton *btn = [SKButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (imageName) {
        [btn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    btn.clickAction = clickAction;
    return btn;

}

+ (UIButton *)createTitleButtonWithFrame:(CGRect)frame
                                   title:(NSString *)title
                              titleColor:(UIColor *)titleColor
                               titleFont:(UIFont *)titleFont
                             clickAction:(void(^)(UIButton *btn))clickAction {
    
    SKButton *btn = [SKButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    if (title) {
        [btn setTitle:title forState:UIControlStateNormal];
    }
    if (titleColor) {
        [btn setTitleColor:titleColor forState:0];
    }
    if (titleFont) {
        btn.titleLabel.font = titleFont;
    }
    btn.clickAction = clickAction;
    return btn;
}

+ (UIButton *) buttonWithImage:(NSString *)imageName
                 highlighImage:(NSString *)hightlighImageName
                   selectImage:(NSString *)selectImageName
                     addTarget:(id)target
                        action:(SEL)action {

    return [self buttonWithTitle:nil titleColor:nil titleFont:nil image:imageName highlighImage:hightlighImageName selectImage:selectImageName addTarget:target action:action];
}

+ (UIButton *) buttonWithTitle:(NSString *)buttonTitle
                    titleColor:(UIColor *)titleColor
                     titleFont:(UIFont *)titleFont
                     addTarget:(id)target
                        action:(SEL)action {

    return [self buttonWithTitle:buttonTitle titleColor:titleColor titleFont:titleFont image:nil highlighImage:nil selectImage:nil addTarget:target action:action];
}

+ (UIButton *) buttonWithTitle:(NSString *)buttonTitle
                    titleColor:(UIColor *)titleColor
                     titleFont:(UIFont *)titleFont
                         image:(NSString *)imageName
                 highlighImage:(NSString *)hightlighImageName
                   selectImage:(NSString *)selectImageName
                     addTarget:(id)target
                        action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (buttonTitle) {
        [btn setTitle:buttonTitle forState:UIControlStateNormal];
    }
    if (titleColor) {
        [btn setTitleColor:titleColor forState:0];
    }
    if (titleFont) {
        btn.titleLabel.font = titleFont;
    }
    if (imageName) {
        [btn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    if (hightlighImageName) {
        [btn setImage:[UIImage imageNamed:hightlighImageName] forState:UIControlStateHighlighted];
    }
    if (selectImageName) {
        [btn setImage:[UIImage imageNamed:selectImageName] forState:UIControlStateSelected];
    }
    if (target && action) {
        [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    return btn;
}

@end
