// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushScatterEffect.h"

#import "LTCGExtensions.h"
#import "LTRotatedRect.h"

@implementation LTBrushScatterEffect

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self setScatterEffectDefaults];
  }
  return self;
}

- (void)setScatterEffectDefaults {
  self.scatter = self.defaultScatter;
  self.count = self.defaultCount;
  self.countJitter = self.defaultCountJitter;
}

#pragma mark -
#pragma mark Effect
#pragma mark -

- (NSMutableArray *)scatteredRectsFromRects:(NSArray *)rects {
  LTParameterAssert(rects);
  srand48(arc4random());
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
  return arc4random_uniform((uint)maxCount - (uint)minCount) + minCount;
}

- (LTRotatedRect *)randomRectFromRect:(LTRotatedRect *)rect {
  CGFloat randX = drand48() * 2 - 1;
  CGFloat randY = drand48() * 2 - 1;
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
