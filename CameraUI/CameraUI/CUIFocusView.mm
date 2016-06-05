// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIFocusView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIFocusView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
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

- (void)setOutlineColor:(nullable UIColor *)outlineColor {
  _outlineColor = outlineColor;
  [self setNeedsDisplay];
}

- (void)setPlusLength:(CGFloat)plusLength {
  _plusLength = plusLength;
  [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth {
  _lineWidth = lineWidth;
  [self setNeedsDisplay];
}

- (void)setOutlineWidth:(CGFloat)outlineWidth {
  _outlineWidth = outlineWidth;
  [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Draw
#pragma mark -

- (void)drawRect:(CGRect __unused)rect {
  [self drawRectLine];
  [self drawPlusInCenter];
}

- (void)drawRectLine {
  CGFloat strokeInset = self.outlineStroke / 2;
  CGRect rectLine = CGRectInset(self.bounds, strokeInset, strokeInset);
  UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:rectLine];

  rectPath.lineWidth = self.outlineStroke;
  [self.outlineColor setStroke];
  [rectPath stroke];

  rectPath.lineWidth = self.lineWidth;
  [self.color setStroke];
  [rectPath stroke];
}

- (void)drawPlusInCenter {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, self.bounds.size.width / 2, self.bounds.size.height / 2);
  [self drawPlusOutline];
  [self drawPlus];
  CGContextRestoreGState(context);
}

- (void)drawPlusOutline {
  CGFloat plusOutlineLength = self.plusLength + 2 * self.outlineWidth;
  UIBezierPath *plusOutlinePath = [self plusBezierPathWithLength:plusOutlineLength];
  plusOutlinePath.lineWidth = self.outlineStroke;
  [self.outlineColor setStroke];
  [plusOutlinePath stroke];
}

- (void)drawPlus {
  UIBezierPath *plusPath = [self plusBezierPathWithLength:self.plusLength];
  plusPath.lineWidth = self.lineWidth;
  [self.color setStroke];
  [plusPath stroke];
}

- (UIBezierPath *)plusBezierPathWithLength:(CGFloat)plusLength {
  CGFloat halfLength = plusLength / 2;
  UIBezierPath *plusPath = [UIBezierPath bezierPath];
  [plusPath moveToPoint:CGPointMake(-halfLength, 0)];
  [plusPath addLineToPoint:CGPointMake(halfLength, 0)];
  [plusPath moveToPoint:CGPointMake(0, -halfLength)];
  [plusPath addLineToPoint:CGPointMake(0, halfLength)];
  return plusPath;
}

- (CGFloat)outlineStroke {
  return self.lineWidth + 2 * self.outlineWidth;
}

@end

NS_ASSUME_NONNULL_END
