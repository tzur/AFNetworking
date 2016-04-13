// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WFTransparentView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WFTransparentView

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
  for (UIView *view in self.subviews) {
    if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled &&
        [view pointInside:[self convertPoint:point toView:view] withEvent:event]) {
      return YES;
    }
  }
  return NO;
}

@end

NS_ASSUME_NONNULL_END
