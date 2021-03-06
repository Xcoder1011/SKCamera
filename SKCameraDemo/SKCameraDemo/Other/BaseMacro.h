//
//  BaseMacro.h
//  LiveRoomGiftAnimations
//
//  Created by KUN on 17/5/5.
//  Copyright © 2017年 animation. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <sys/time.h>
#import <pthread.h>

#ifndef BaseMacro_h
#define BaseMacro_h


#ifdef DEBUG
#    define NSLog(...) NSLog(__VA_ARGS__)
#else
#    define NSLog(...) {}
#endif

#ifdef DEBUG
#   define DDLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#   define DDLog(...) do { } while (0)
#endif


#ifndef kWeakObj
    #if __has_feature(objc_arc)
    #define kWeakObj(obj)  __weak typeof(obj)  weak##obj = obj;
    #else
    #define kWeakObj(obj)  __block typeof(obj)  weak##obj = obj;
    #endif
#endif

#ifndef kStrongObj
    #if __has_feature(objc_arc)
    #define kStrongObj(obj) __strong __typeof(obj)  obj = weak##obj;
    #else
    #define kStrongObj(obj) __strong __typeof(obj)  obj = weak##obj;
    #endif
#endif


#define DeviceRect   [UIScreen mainScreen].bounds
#define DeviceHeight [UIScreen mainScreen].bounds.size.height
#define DeviceWidth  [UIScreen mainScreen].bounds.size.width

#define kscaleDeviceWidth(width)  (width/3 *DeviceWidth)/414.0
#define kscaleDeviceHeight(height)  (height/3 *DeviceHeight)/736.0

static inline bool dispatch_is_main_queue() {
    return pthread_main_np() != 0;
}

static inline void dispatch_async_on_main_queue(void(^block)()) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static inline void dispatch_sync_on_main_queue(void(^block)()) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


static inline void dispatch_async_on_global_queue(void(^block)()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static inline void dispatch_async_on_globalqueue_then_on_mainqueue(void(^globalblock)(),void(^mainblock)()){
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         globalblock();
         dispatch_async_on_main_queue(mainblock);
     });
}


static inline UIButton * createImgButton(CGRect frame, NSString *imageName ,id target, SEL sel) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (imageName) {
        [btn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    }
    if (target && sel) {
        [btn addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    }
    return btn;
}

static inline UIButton * createTitleButton(CGRect frame, NSString *buttonTitle, UIColor *titleColor ,UIFont *titleFont,id target, SEL sel) {
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
    if (target && sel) {
        [btn addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    }
    return btn;
}



#endif /* BaseMacro_h */
