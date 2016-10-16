// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIGridView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIGridView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
    self.userInteractionEnabled = NO;
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
  [self drawGrid];
}

- (void)drawGrid {
  UIBezierPath *gridPath = [self gridPath];

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
  CGFloat y = CGRectGetMinY(self.bounds) + std::round(yPortion * self.bounds.size.height);
  [path moveToPoint:CGPointMake(CGRectGetMinX(self.bounds), y)];
  [path addLineToPoint:CGPointMake(CGRectGetMaxX(self.bounds), y)];
}

- (void)addVerticalLineToPath:(UIBezierPath *)path atPortion:(CGFloat)xPortion {
  CGFloat x = CGRectGetMinX(self.bounds) + std::round(xPortion * self.bounds.size.width);
  [path moveToPoint:CGPointMake(x, CGRectGetMinY(self.bounds))];
  [path addLineToPoint:CGPointMake(x, CGRectGetMaxY(self.bounds))];
}

@end

@implementation CUIGridView (Factory)

+ (CUIGridView *)whiteGrid {
  CUIGridView *gridView = [[CUIGridView alloc] initWithFrame:CGRectZero];
  gridView.lineWidth = 0.5;
  gridView.color = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
  gridView.shadowRadius = 1;
  gridView.shadowColor = [UIColor blackColor];
  gridView.shadowOpacity = 0.25;
  return  gridView;
}

@end

NS_ASSUME_NONNULL_END
