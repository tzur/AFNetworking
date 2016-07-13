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
  UIBezierPath* arcPath = [UIBezierPath bezierPath];
  [arcPath addArcWithCenter:CGRectCenter(buttonTraits.bounds) radius:self.radius
                 startAngle:self.startAngle endAngle:self.endAngle clockwise:self.clockwise];
  arcPath.lineWidth = self.width;
  [self.color setStroke];
  [arcPath stroke];
}

@end

@implementation CUIProgressRingDrawer

- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits {
  UIBezierPath* arcPath = [UIBezierPath bezierPath];
  [arcPath addArcWithCenter:CGRectCenter(buttonTraits.bounds) radius:self.radius
                 startAngle:self.startAngle
                   endAngle:self.startAngle + 2 * M_PI * buttonTraits.progress
                  clockwise:self.clockwise];
  arcPath.lineWidth = self.width;
  [self.color setStroke];
  [arcPath stroke];
}

@end

NS_ASSUME_NONNULL_END
