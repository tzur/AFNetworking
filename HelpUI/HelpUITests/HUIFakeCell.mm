// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "HUIFakeCell.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HUIFakeCell

- (void)startAnimation {
  self.animating = YES;
}

- (void)stopAnimation {
  self.animating = NO;
}

@end

NS_ASSUME_NONNULL_END
