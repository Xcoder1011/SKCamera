//
//  UIButton+PreventMultipleClicks.m
//  FaceCall
//
//  Created by KUN on 16/11/28.
//  Copyright © 2016年 AiYan. All rights reserved.
//

#import "UIButton+PreventMultipleClicks.h"
#import <objc/runtime.h>

@interface UIButton ()
/**
 *  bool YES 忽略点击事件   NO 允许点击事件
 */
@property (nonatomic, assign) BOOL isIgnoreEvent;
@end

@implementation UIButton (PreventMultipleClicks)

static void  *kClicktimerIntervalKey = &kClicktimerIntervalKey;

static const char *kIsIgnoreEventKey = "kIsIgnoreEventKey";


+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SEL selector1 = @selector(sendAction:to:forEvent:);
        SEL selector2 = @selector(preventMultipleClickAction:to:forEvent:);

        Method method1 = class_getInstanceMethod(self, selector1);
        Method method2 = class_getInstanceMethod(self, selector2);
        
        // 将 method2的实现 添加到系统方法中 也就是说 将 method1方法指针添加成 方法method2的  返回值表示是否添加成功
        BOOL isAddSuccess = class_addMethod(self, selector1, method_getImplementation(method2), method_getTypeEncoding(method2));
        
        if (isAddSuccess) { // 如果替换系统方法成功
            // 添加成功了 说明 本类中不存在method2 所以此时必须将方法2的实现指针换成方法1的，否则 2方法将没有实现。
            class_replaceMethod(self, selector2, method_getImplementation(method1), method_getTypeEncoding(method1));
                                
        } else {
            //添加失败了 说明本类中 有method2的实现，此时只需要将 method1和method2的IMP互换一下即可。
            method_exchangeImplementations(method1, method2);
        }
        
    });

}

// 当点击事件 sendAction 时  将会执行  preventMultipleClickAction
- (void)preventMultipleClickAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    
    if (!self.isNeedPrevent) { // 不需要防止多次点击
        [self preventMultipleClickAction:action to:target forEvent:event];
        return;
    }
    
    // 需要防止多次点击
    self.clicktimerInterval = self.clicktimerInterval == 0 ? defaultClicktimerInterval :  self.clicktimerInterval;
    
    if (self.isIgnoreEvent) {
        return;
        
    } else if (self.clicktimerInterval > 0) {
    
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.clicktimerInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //
            [self setIsIgnoreEvent:NO];
        });
    }

    self.isIgnoreEvent = YES;
     // 这里看上去会陷入递归调用死循环，但在运行期此方法是和sendAction:to:forEvent:互换的，相当于执行sendAction:to:forEvent:方法，所以并不会陷入死循环。
    [self preventMultipleClickAction:action to:target forEvent:event];
}


- (void)setIsIgnoreEvent:(BOOL)isIgnoreEvent {
    
    objc_setAssociatedObject(self, kIsIgnoreEventKey, @(isIgnoreEvent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isIgnoreEvent {
    
    return [objc_getAssociatedObject(self, kIsIgnoreEventKey) boolValue];
}

- (void)setClicktimerInterval:(NSTimeInterval)clicktimerInterval {

    objc_setAssociatedObject(self, kClicktimerIntervalKey, @(clicktimerInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)clicktimerInterval {

    return [objc_getAssociatedObject(self, kClicktimerIntervalKey) doubleValue];
}


- (void)setIsNeedPrevent:(BOOL)isNeedPrevent {
    // 把一个对象与另外一个对象进行关联
    objc_setAssociatedObject(self, @selector(isNeedPrevent), @(isNeedPrevent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isNeedPrevent {
    //  获取相关联的对象,
    // _cmd : 当前方法的一个SEL指针
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end
