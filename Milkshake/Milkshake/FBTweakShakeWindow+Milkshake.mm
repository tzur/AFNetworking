// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBTweakShakeWindow+Milkshake.h"

#import <FBTweak/FBTweakShakeWindow.h>

NS_ASSUME_NONNULL_BEGIN

void SHKDismissTweaksViewController() {
  auto _Nullable window = [UIApplication sharedApplication].keyWindow;
  if (![window isKindOfClass:[FBTweakShakeWindow class]]) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    [(FBTweakShakeWindow *)window dismissTweaksViewController];
  });
}

NS_ASSUME_NONNULL_END
