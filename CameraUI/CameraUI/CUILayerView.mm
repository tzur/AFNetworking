// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUILayerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUILayerView ()

/// Displayed layer.
@property (readonly, nonatomic) CALayer *internalLayer;

@end

@implementation CUILayerView

- (instancetype)initWithLayer:(CALayer *)layer {
  if (self = [super initWithFrame:CGRectZero]) {
    _internalLayer = layer;
    [self.layer addSublayer:layer];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.internalLayer.frame = self.layer.bounds;
}

@end

NS_ASSUME_NONNULL_END
