// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFGradientView.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WFGradientView

+ (instancetype)horizontalGradientWithLeftColor:(UIColor *)leftColor
                                     rightColor:(UIColor *)rightColor {
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];
  view.colors = @[leftColor, rightColor];
  return view;
}

+ (instancetype)verticalGradientWithTopColor:(UIColor *)topColor
                                 bottomColor:(UIColor *)bottomColor {
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];
  view.colors = @[topColor, bottomColor];
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
  self.colors = @[[UIColor clearColor], [UIColor clearColor]];
}

- (UIColor *)startColor {
  return self.colors.firstObject;
}

- (UIColor *)endColor {
  return self.colors.lastObject;
}

- (void)setStartColor:(UIColor *)startColor {
  NSMutableArray<UIColor *> *colors = [self.colors mutableCopy];
  colors[0] = startColor;
  self.colors = colors;
}

- (void)setEndColor:(UIColor *)endColor {
  NSMutableArray<UIColor *> *colors = [self.colors mutableCopy];
  colors[colors.count - 1] = endColor;
  self.colors = colors;
}

- (void)setColors:(NSArray<UIColor *> *)colors {
  LTParameterAssert(colors.count > 1, @"Invalid colors array, must have at least 2 element");
  _colors = [colors copy];
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
  CAGradientLayer *layer = (CAGradientLayer *)self.layer;
  layer.startPoint = self.startPoint;
  layer.endPoint = self.endPoint;
  layer.colors = [self.colors lt_map:^id(UIColor *color) {
    return (__bridge id)color.CGColor;
  }];
}

@end

NS_ASSUME_NONNULL_END
