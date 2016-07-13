// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIGridView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIGridView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
    self.userInteractionEnabled = NO;
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
  [self drawGrid];
}

- (void)drawGrid {
  UIBezierPath *gridPath = [self gridPath];

  gridPath.lineWidth = [self outlineStroke];
  [self.outlineColor setStroke];
  [gridPath stroke];

  gridPath.lineWidth = self.lineWidth;
  [self.color setStroke];
  [gridPath stroke];
}

- (UIBezierPath *)gridPath {
  UIBezierPath *gridPath = [UIBezierPath bezierPath];
  [self addHorizontalLineToPath:gridPath atPortion:(1.0 / 3.0)];
  [self addHorizontalLineToPath:gridPath atPortion:(2.0 / 3.0)];
  [self addVerticalLineToPath:gridPath atPortion:(1.0 / 3.0)];
  [self addVerticalLineToPath:gridPath atPortion:(2.0 / 3.0)];
  return gridPath;
}

- (void)addHorizontalLineToPath:(UIBezierPath *)path atPortion:(CGFloat)yPortion {
  CGFloat y = CGRectGetMinY(self.bounds) + yPortion * self.bounds.size.height;
  [path moveToPoint:CGPointMake(CGRectGetMinX(self.bounds), y)];
  [path addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), y)];
}

- (void)addVerticalLineToPath:(UIBezierPath *)path atPortion:(CGFloat)xPortion {
  CGFloat x = CGRectGetMinX(self.bounds) + xPortion * self.bounds.size.width;
  [path moveToPoint:CGPointMake(x, CGRectGetMinY(self.bounds))];
  [path addLineToPoint:CGPointMake(x, CGRectGetMaxY(self.bounds))];
}

- (CGFloat)outlineStroke {
  return self.lineWidth + 2 * self.outlineWidth;
}

@end

@implementation CUIGridView (Factory)

+ (CUIGridView *)whiteGrid {
  CUIGridView *gridView = [[CUIGridView alloc] initWithFrame:CGRectZero];
  gridView.lineWidth = 1;
  gridView.color = [UIColor whiteColor];
  gridView.outlineWidth = 0.5;
  gridView.outlineColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
  return  gridView;
}

@end

NS_ASSUME_NONNULL_END
