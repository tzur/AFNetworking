// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIView+Retrieval.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIView (Retrieval)

- (nullable __kindof UIView *)wf_viewForAccessibilityIdentifier:(NSString *)
    accessibilityIdentifier {
  LTParameterAssert(accessibilityIdentifier);

  if ([self.accessibilityIdentifier isEqualToString:accessibilityIdentifier]) {
    return self;
  }

  for (UIView *subview in self.subviews) {
    UIView * _Nullable view = [subview wf_viewForAccessibilityIdentifier:accessibilityIdentifier];
    if (view) {
      return view;
    }
  }

  return nil;
}

@end

NS_ASSUME_NONNULL_END
