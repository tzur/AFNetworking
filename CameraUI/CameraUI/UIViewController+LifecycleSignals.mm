// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "UIViewController+LifecycleSignals.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (LifecycleSignals)

- (RACSignal *)cui_isVisible {
  return [self cui_isVisibleWithNotificationCenter:[NSNotificationCenter defaultCenter]];
}

- (RACSignal *)cui_isVisibleWithNotificationCenter:(NSNotificationCenter *)notificationCenter {
  return [[RACSignal
      merge:@[
        [[self cui_toForegroundFromNotificationCenter:notificationCenter] mapReplace:@YES],
        [[self rac_signalForSelector:@selector(viewWillAppear:)] mapReplace:@YES],
        [[self cui_toBackgroundFromNotificationCenter:notificationCenter] mapReplace:@NO],
        [[self rac_signalForSelector:@selector(viewDidDisappear:)] mapReplace:@NO]
      ]]
      distinctUntilChanged];
}

- (RACSignal *)cui_toForegroundFromNotificationCenter:(NSNotificationCenter *)notificationCenter {
  return [self cui_observeName:UIApplicationWillEnterForegroundNotification
        fromNotificationCenter:notificationCenter];
}

- (RACSignal *)cui_toBackgroundFromNotificationCenter:(NSNotificationCenter *)notificationCenter {
  return [self cui_observeName:UIApplicationDidEnterBackgroundNotification
        fromNotificationCenter:notificationCenter];
}

- (RACSignal *)cui_observeName:(NSString *)name
        fromNotificationCenter:(NSNotificationCenter *)notificationCenter {
  return [[notificationCenter
      rac_addObserverForName:name object:nil]
      takeUntil:[self rac_willDeallocSignal]];
}

@end

NS_ASSUME_NONNULL_END
