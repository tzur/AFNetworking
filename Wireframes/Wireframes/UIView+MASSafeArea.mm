// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dana Feischer.

#import "UIView+MASSafeArea.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIView (MASSafeArea)

- (MASViewAttribute *)wf_safeArea {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuide;
  }
  return [[MASViewAttribute alloc] initWithView:self
                                layoutAttribute:NSLayoutAttributeNotAnAttribute];
}

- (MASViewAttribute *)wf_safeAreaLeft {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuideLeft;
  }
  return self.mas_left;
}

- (MASViewAttribute *)wf_safeAreaRight {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuideRight;
  }
  return self.mas_right;
}

- (MASViewAttribute *)wf_safeAreaTop {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuideTop;
  }
  return self.mas_top;
}

- (MASViewAttribute *)wf_safeAreaBottom {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuideBottom;
  }
  return self.mas_bottom;
}

- (MASViewAttribute *)wf_safeAreaHeight {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuideHeight;
  }
  return self.mas_height;
}

- (MASViewAttribute *)wf_safeAreaWidth {
  if (@available(iOS 11.0, *)) {
    return self.mas_safeAreaLayoutGuideWidth;
  }
  return self.mas_width;
}

@end

NS_ASSUME_NONNULL_END
