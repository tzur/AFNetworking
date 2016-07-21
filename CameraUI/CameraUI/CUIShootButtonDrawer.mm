// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIShootButtonDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIOvalDrawer

- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits {
  CGRect ovalRect = CGRectCenteredAt(CGRectCenter(buttonTraits.bounds), self.size);
  UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:ovalRect];
  UIColor *ovalColor = buttonTraits.highlighted ? self.highlightColor : self.color;
  [ovalColor setFill];
  [ovalPath fill];
}

@end

@implementation CUIRectDrawer

- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits {
  CGRect rect = CGRectCenteredAt(CGRectCenter(buttonTraits.bounds), self.size);
  UIBezierPath *rectPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                      cornerRadius:self.cornerRadius];
  UIColor *rectColor = buttonTraits.highlighted ? self.highlightColor : self.color;
  [rectColor setFill];
  [rectPath fill];
}

@end

@implementation CUIArcDrawer

- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits {
  UIBezierPath *arcPath = [UIBezierPath bezierPath];
  [arcPath addArcWithCenter:CGRectCenter(buttonTraits.bounds) radius:self.radius
                 startAngle:self.startAngle endAngle:self.endAngle clockwise:self.clockwise];
  arcPath.lineWidth = self.width;
  [self.color setStroke];
  [arcPath stroke];
}

@end

@implementation CUIGradientRingDrawer

- (instancetype)init {
  if (self = [super init]) {
    _startColor = [UIColor clearColor];
    _endColor = [UIColor clearColor];
    _startPoint = CGPointMake(0, 0.5);
    _endPoint = CGPointMake(1, 0.5);
  }
  return self;
}

- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits {
  CGPoint center = CGRectCenter(buttonTraits.bounds);

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);

  CGContextAddArc(context, center.x, center.y, self.radius + self.width / 2, 0,
                  (CGFloat)(2 * M_PI), YES);
  CGContextAddArc(context, center.x, center.y, self.radius - self.width / 2, 0,
                  (CGFloat)(2 * M_PI), NO);
  CGContextEOClip(context);

  lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB());
  NSArray *colors = @[(__bridge id)self.startColor.CGColor, (__bridge id)self.endColor.CGColor];
  CGFloat locations[] = {0, 1};
  lt::Ref<CGGradientRef> gradient(CGGradientCreateWithColors(colorSpace.get(),
                                                             (__bridge CFArrayRef)colors,
                                                             locations));

  CGPoint startPoint = self.startPoint * buttonTraits.bounds.size;
  CGPoint endPoint = self.endPoint * buttonTraits.bounds.size;
  CGContextDrawLinearGradient(context, gradient.get(), startPoint, endPoint, 0);

  CGContextRestoreGState(context);
}

@end

@implementation CUIProgressRingDrawer

- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits {
  UIBezierPath *arcPath = [UIBezierPath bezierPath];
  [arcPath addArcWithCenter:CGRectCenter(buttonTraits.bounds) radius:self.radius
                 startAngle:self.startAngle
                   endAngle:(CGFloat)(self.startAngle + 2 * M_PI * buttonTraits.progress)
                  clockwise:self.clockwise];
  arcPath.lineWidth = self.width;
  [self.color setStroke];
  [arcPath stroke];
}

@end

NS_ASSUME_NONNULL_END
