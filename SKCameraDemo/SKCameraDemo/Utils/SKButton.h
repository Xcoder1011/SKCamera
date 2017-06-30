//
//  SKButton.h
//  SKCameraDemo
//
//  Created by KUN on 17/5/25.
//  Copyright © 2017年 lemon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKButton : UIButton

// taret :self , SEL : clicAction block
@property (nonatomic , copy) void(^clickAction)(UIButton *btn);

@property(nonatomic, copy) SKButton *(^frame_)(CGRect frame);

@property(nonatomic, copy) SKButton *(^title_)(NSString *title);

@property(nonatomic, copy) SKButton *(^color_)(UIColor *color);

@property(nonatomic, copy) SKButton *(^font_)(UIFont *font);

@property(nonatomic, copy) SKButton *(^imageName_)(NSString *imageName);

@property(nonatomic, copy) SKButton *(^hightlighImageName_)(NSString *hightlighImageName);

@property(nonatomic, copy) SKButton *(^selectImageName_)(NSString *selectImageName);

@property(nonatomic, copy) SKButton *(^target_and_Action_)(id target , SEL action);

@property(nonatomic, copy) SKButton *(^clickAction_)(void(^clickAction)(UIButton *btn));

+ (instancetype)buttonWith:(void(^)(SKButton *btn))initblock;

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
