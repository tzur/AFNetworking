// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFGradientView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WFGradientView

+ (instancetype)horizontalGradientWithLeftColor:(UIColor *)leftColor
                                     rightColor:(UIColor *)rightColor {
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];
  view.startColor = leftColor;
  view.endColor = rightColor;
  return view;
}

+ (instancetype)verticalGradientWithTopColor:(UIColor *)topColor
                                 bottomColor:(UIColor *)bottomColor {
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];
  view.startColor = topColor;
  view.endColor = bottomColor;
  view.startPoint = CGPointMake(0.5, 0);
  view.endPoint = CGPointMake(0.5, 1);
  return view;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setup];
  }
  return self;
}

+ (Class)layerClass {
  return CAGradientLayer.class;
}

- (void)setup {
  self.startPoint = CGPointMake(0, 0.5);
  self.endPoint = CGPointMake(1, 0.5);
  self.startColor = [UIColor clearColor];
  self.endColor = [UIColor clearColor];
}

- (void)setStartColor:(UIColor *)startColor {
  _startColor = startColor;
  [self updateGradientLayer];
}

- (void)setEndColor:(UIColor *)endColor {
  _endColor = endColor;
  [self updateGradientLayer];
}

- (void)setStartPoint:(CGPoint)startPoint {
  _startPoint = startPoint;
  [self updateGradientLayer];
}

- (void)setEndPoint:(CGPoint)endPoint {
  _endPoint = endPoint;
  [self updateGradientLayer];
}

- (void)updateGradientLayer {
  if (!self.startColor || !self.endColor) {
    return;
  }

  CAGradientLayer *layer = (CAGradientLayer *)self.layer;
  layer.colors = @[(__bridge id)self.startColor.CGColor, (__bridge id)self.endColor.CGColor];
  layer.startPoint = self.startPoint;
  layer.endPoint = self.endPoint;
}

@end

NS_ASSUME_NONNULL_END
