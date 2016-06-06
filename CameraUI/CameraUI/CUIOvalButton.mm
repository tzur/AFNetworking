// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIOvalButton.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIOvalButton

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
  }
  return self;
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawRect:(CGRect __unused)rect {
  CGPoint center = CGRectCenter(self.bounds);
  [self drawOvalWithCenter:center];
  [self drawRingWithCenter:center];
}

- (void)drawOvalWithCenter:(CGPoint)center {
  CGRect ovalRect = CGRectCenteredAt(center, self.ovalSize);
  UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:ovalRect];
  UIColor *ovalColor = self.highlighted ? self.highlightColor : self.color;
  [ovalColor setFill];
  [ovalPath fill];
}

- (void)drawRingWithCenter:(CGPoint)center {
  CGRect ringRect = CGRectCenteredAt(center, self.ringSize - CGSizeMakeUniform(self.ringWidth));
  UIBezierPath *ringPath = [UIBezierPath bezierPathWithOvalInRect:ringRect];
  ringPath.lineWidth = self.ringWidth;
  [self.color setStroke];
  [ringPath stroke];
}

#pragma mark -
#pragma mark Setters
#pragma mark -

- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  [self updateAlpha];
}

- (void)updateAlpha {
  self.alpha = self.enabled ? 1 : self.disabledAlpha;
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  [self setNeedsDisplay];
}

- (void)setRingSize:(CGSize)ringSize {
  _ringSize = ringSize;
  [self setNeedsDisplay];
}

- (void)setRingWidth:(CGFloat)ringWidth {
  _ringWidth = ringWidth;
  [self setNeedsDisplay];
}

- (void)setOvalSize:(CGSize)ovalSize {
  _ovalSize = ovalSize;
  [self setNeedsDisplay];
}

- (void)setColor:(nullable UIColor *)color {
  _color = color;
  [self setNeedsDisplay];
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha {
  _disabledAlpha = disabledAlpha;
  [self updateAlpha];
}

- (void)setHighlightColor:(nullable UIColor *)highlightColor {
  _highlightColor = highlightColor;
  [self setNeedsDisplay];
}

@end

NS_ASSUME_NONNULL_END
