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
static BOOL _didAccessView;

+ (void)beforeEach {
  _didAccessView = NO;
  _keyWindowView = [[UIView alloc] initWithFrame:CGRectZero];
  [[UIApplication sharedApplication].keyWindow addSubview:_keyWindowView];
}

+ (void)afterEach {
  [_keyWindowView removeFromSuperview];
  _keyWindowView = nil;

  // Skip the current run loop to allow for release of objects retained by UIKit. This is required
  // when the added view is the view of a \c UIViewController, as UIKit retains said view controller
  // until the runloop is spun for a single time.
  if (_didAccessView) {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.001];
    [[NSRunLoop currentRunLoop] runUntilDate:date];
  }
}

+ (UIView *)keyWindowView {
  _didAccessView = YES;
  return _keyWindowView;
}

@end

NS_ASSUME_NONNULL_END
