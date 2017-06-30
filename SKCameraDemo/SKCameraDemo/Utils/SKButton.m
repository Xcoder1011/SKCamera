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

+ (instancetype)buttonWith:(void(^)(SKButton *btn))initblock {
    
    SKButton *btn = [SKButton buttonWithType:UIButtonTypeCustom];
    if (initblock) {
        initblock(btn);
    }
    return btn;
}

- (SKButton *(^)(CGRect))frame_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(CGRect rect) {
        
        weakself.frame = rect;
        
        return weakself;
    };
}

- (SKButton *(^)(NSString *))title_ {
    
    __weak typeof(self) weakself = self;
    
    SKButton * (^setTitle)(NSString *) = ^(NSString *str) {
        
        [weakself setTitle:str forState:UIControlStateNormal];
        
        return weakself;
    };
    
    return setTitle;
}

- (SKButton *(^)(UIColor *))color_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(UIColor *color) {
        
        [weakself setTitleColor:color forState:0];
        
        return weakself;
    };
}

- (SKButton *(^)(NSString *))imageName_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(NSString * name) {
        
        [weakself setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
        
        return self;
    };
}

- (SKButton *(^)(NSString *))hightlighImageName_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(NSString * name) {
        
        [weakself setImage:[UIImage imageNamed:name] forState:UIControlStateHighlighted];
        
        return self;
    };
}

- (SKButton *(^)(NSString *))selectImageName_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(NSString * name) {
        
        [weakself setImage:[UIImage imageNamed:name] forState:UIControlStateSelected];
        
        return self;
    };
}

- (SKButton *(^)(id, SEL))target_and_Action_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(id target , SEL action) {
        
        [weakself addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        
        return weakself;
    };
}

- (SKButton *(^)(void (^)(UIButton *)))clickAction_ {
    
    __weak typeof(self) weakself = self;
    
    return ^(void (^clickBlock)(UIButton *btn)) {
        
        weakself.clickAction = clickBlock;
        
        return self;
    };
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
