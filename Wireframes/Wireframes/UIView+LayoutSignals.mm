// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "UIView+LayoutSignals.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIView (LayoutSignals)

- (RACSignal<NSValue *> *)wf_layoutSubviewsSignal {
  @weakify(self);
  return [[[self rac_signalForSelector:@selector(layoutSubviews)]
      map:^NSValue *(RACTuple *) {
        @strongify(self);
        return $(self.bounds);
      }]
      setNameWithFormat:@"%@ -wf_layoutSubviewSignal", self];
}

- (RACSignal<NSValue *> *)wf_boundsSignal {
  RACSignal<NSValue *> * _Nullable signal = objc_getAssociatedObject(self, _cmd);
  if (signal) {
    return signal;
  }

  signal = [[[self.wf_currentBounds
      concat:self.wf_layoutSubviewsSignal]
      distinctUntilChanged]
      setNameWithFormat:@"%@ -wf_boundsSignal", self];

  objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return signal;
}

- (RACSignal<NSValue *> *)wf_currentBounds {
  @weakify(self);
  return [RACSignal defer:^{
    @strongify(self);
    return [RACSignal return:$(self.bounds)];
  }];
}

- (RACSignal<NSValue *> *)wf_sizeSignal {
  RACSignal<NSValue *> * _Nullable signal = objc_getAssociatedObject(self, _cmd);
  if (signal) {
    return signal;
  };

  signal = [[[self.wf_boundsSignal
      map:^NSValue *(NSValue *bounds) {
        return $([bounds CGRectValue].size);
      }]
      distinctUntilChanged]
      setNameWithFormat:@"%@ -wf_sizeSignal", self];

  objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return signal;
}

- (RACSignal<NSValue *> *)wf_positiveSizeSignal {
  RACSignal<NSValue *> * _Nullable signal = objc_getAssociatedObject(self, _cmd);
  if (signal) {
    return signal;
  };

  signal = [[[[self wf_sizeSignal]
      filter:^BOOL(NSValue *value) {
        CGSize size = [value CGSizeValue];
        return size.width > 0 && size.height > 0;
      }]
      distinctUntilChanged]
      setNameWithFormat:@"%@ -wf_positiveSizeSignal", self];

  objc_setAssociatedObject(self, _cmd, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return signal;
}

@end

NS_ASSUME_NONNULL_END
