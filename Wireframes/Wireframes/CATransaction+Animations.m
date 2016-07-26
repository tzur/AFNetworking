// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "CATransaction+Animations.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CATransaction (Animations)

+ (void)performWithoutAnimation:(LTVoidBlock)block {
  LTParameterAssert(block);

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  block();
  [CATransaction commit];
}

@end

NS_ASSUME_NONNULL_END
