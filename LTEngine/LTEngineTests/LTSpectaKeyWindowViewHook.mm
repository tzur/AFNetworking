// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTSpectaKeyWindowViewHook.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTSpectaKeyWindowViewHook ()

/// View which is inserted under the key window.
+ (UIView *)keyWindowView;

@end

void LTAddViewToWindow(UIView *view) {
  [[LTSpectaKeyWindowViewHook keyWindowView] addSubview:view];
}

@implementation LTSpectaKeyWindowViewHook

static UIView *_keyWindowView;

+ (void)beforeEach {
  _keyWindowView = [[UIView alloc] initWithFrame:CGRectZero];
  [[UIApplication sharedApplication].keyWindow addSubview:_keyWindowView];
}

+ (void)afterEach {
  [_keyWindowView removeFromSuperview];
  _keyWindowView = nil;
}

+ (UIView *)keyWindowView {
  return _keyWindowView;
}

@end

NS_ASSUME_NONNULL_END
