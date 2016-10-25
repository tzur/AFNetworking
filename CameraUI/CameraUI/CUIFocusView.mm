// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIFocusView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIFocusView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
  }
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setColor:(nullable UIColor *)color {
  _color = color;
  [self setNeedsDisplay];
}

- (void)setIndicatorLength:(CGFloat)indicatorLength {
  _indicatorLength = indicatorLength;
  [self setNeedsDisplay];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
  _cornerRadius = cornerRadius;
  [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth {
  _lineWidth = lineWidth;
  [self setNeedsDisplay];
}

- (void)setShadowColor:(nullable UIColor *)shadowColor {
  self.layer.shadowColor = shadowColor.CGColor;
}

- (nullable UIColor *)shadowColor {
  return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
  self.layer.shadowRadius = shadowRadius;
}

- (CGFloat)shadowRadius {
  return self.layer.shadowRadius;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
  self.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowOpacity {
  return self.layer.shadowOpacity;
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawRect:(CGRect __unused)rect {
  [self drawRectLine];
  [self drawIndicators];
}

- (void)drawRectLine {
  CGRect rectLine = CGRectInset(self.bounds, [self strokeInset], [self strokeInset]);
  UIBezierPath *rectPath = [UIBezierPath bezierPathWithRoundedRect:rectLine
                                                      cornerRadius:self.cornerRadius];

  rectPath.lineWidth = self.lineWidth;
  [self.color setStroke];
  [rectPath stroke];
}

- (void)drawIndicators {
  UIBezierPath *indicatorsPath = [self indicatorsBezierPathWithRect:self.bounds];

  indicatorsPath.lineWidth = self.lineWidth;
  [self.color setStroke];
  [indicatorsPath stroke];
}

- (UIBezierPath *)indicatorsBezierPathWithRect:(CGRect)rect {
  CGFloat halfWidth = rect.size.width / 2;
  CGFloat halfHeight = rect.size.height / 2;
  UIBezierPath *indicatorsPath = [UIBezierPath bezierPath];
  [indicatorsPath moveToPoint:CGPointMake(halfWidth, [self strokeInset])];
  [indicatorsPath addLineToPoint:CGPointMake(halfWidth, self.indicatorLength)];
  [indicatorsPath moveToPoint:CGPointMake([self strokeInset], halfHeight)];
  [indicatorsPath addLineToPoint:CGPointMake(self.indicatorLength, halfHeight)];
  [indicatorsPath moveToPoint:CGPointMake(halfWidth, rect.size.height - [self strokeInset])];
  [indicatorsPath addLineToPoint:CGPointMake(halfWidth, rect.size.height - self.indicatorLength)];
  [indicatorsPath moveToPoint:CGPointMake(rect.size.width - [self strokeInset], halfHeight)];
  [indicatorsPath addLineToPoint:CGPointMake(rect.size.width - self.indicatorLength, halfHeight)];
  return indicatorsPath;
}

- (CGFloat)strokeInset {
  return self.lineWidth / 2;
}

@end

NS_ASSUME_NONNULL_END
