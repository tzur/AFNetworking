// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushScatterEffect.h"

#import "LTCGExtensions.h"
#import "LTRandom.h"
#import "LTRotatedRect.h"

@implementation LTBrushScatterEffect

#pragma mark -
#pragma mark Effect
#pragma mark -

- (NSMutableArray *)scatteredRectsFromRects:(NSArray *)rects {
  LTParameterAssert(rects);
  NSMutableArray *scattered = [NSMutableArray array];
  for (LTRotatedRect *rect in rects) {
    NSUInteger targetCount = [self randomCount];
    for (NSUInteger i = 0; i < targetCount; ++i) {
      [scattered addObject:[self randomRectFromRect:rect]];
    }
  }
  return scattered;
}

- (NSUInteger)randomCount {
  NSUInteger minCount = std::round(self.count * (1.0 - self.countJitter));
  NSUInteger maxCount = std::round(self.count * (1.0 + self.countJitter));
  return [self.random randomIntegerBetweenMin:(uint)minCount max:(uint)maxCount];
}

- (LTRotatedRect *)randomRectFromRect:(LTRotatedRect *)rect {
  CGFloat randX = [self.random randomDoubleBetweenMin:-1 max:1];
  CGFloat randY = [self.random randomDoubleBetweenMin:-1 max:1];
  CGSize offset = rect.rect.size * CGSizeMake(randX, randY) * self.scatter;
  return [LTRotatedRect rectWithCenter:rect.center + offset size:rect.rect.size angle:rect.angle];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(NSUInteger, count, Count, 1, 16, 1);
LTProperty(CGFloat, scatter, Scatter, 0, 10, 1);
LTProperty(CGFloat, countJitter, CountJitter, 0, 1, 0);

@end
