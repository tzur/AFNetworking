// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "CALayer+Enumeration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CALayer (Enumeration)

- (void)wf_enumerateLayersUsingBlock:(void (^)(CALayer *layer))block {
  LTParameterAssert(block);
  block(self);
  for (CALayer *layer in self.sublayers) {
    [layer wf_enumerateLayersUsingBlock:block];
  }
}

@end

NS_ASSUME_NONNULL_END
