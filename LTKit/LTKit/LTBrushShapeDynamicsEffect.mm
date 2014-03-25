// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushShapeDynamicsEffect.h"

#import "LTCGExtensions.h"
#import "LTRotatedRect.h"

@implementation LTBrushShapeDynamicsEffect

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self setShapeDynamicsEffectDefaults];
  }
  return self;
}

- (void)setShapeDynamicsEffectDefaults {
  self.sizeJitter = self.defaultSizeJitter;
  self.minimumDiameter = self.defaultMinimumDiameter;
  self.angleJitter = self.defaultAngleJitter;
  self.roundnessJitter = self.defaultRoundnessJitter;
  self.minimumRoundness = self.defaultMinimumRoundness;
}

#pragma mark -
#pragma mark Effect
#pragma mark -

- (NSMutableArray *)dynamicRectsFromRects:(NSArray *)rects {
  LTParameterAssert(rects);
  srand48(arc4random());
  NSMutableArray *dynamicRects = [NSMutableArray array];
  for (LTRotatedRect *rect in rects) {
    [dynamicRects addObject:[self randomRectFromRect:rect]];
  }
  return dynamicRects;
}

- (LTRotatedRect *)randomRectFromRect:(LTRotatedRect *)rect {
  CGFloat randomSizeJitter = drand48() * self.sizeJitter;
  CGSize newSize = rect.rect.size - rect.rect.size * randomSizeJitter * (1 - self.minimumDiameter);

  CGFloat randomRoundnessJitter = drand48() * self.roundnessJitter;
  newSize.height = newSize.height * (1 - randomRoundnessJitter * (1 - self.minimumRoundness));
  
  CGFloat randomAngleJitter = (2 * drand48() - 1) * self.angleJitter * M_PI;
  CGFloat newAngle = rect.angle + randomAngleJitter;
  
  LTRotatedRect *newRect = [LTRotatedRect rectWithCenter:rect.center size:newSize angle:newAngle];
  return newRect;
}


#pragma mark -
#pragma mark Properties
#pragma mark -

LTBoundedPrimitivePropertyImplement(CGFloat, sizeJitter, SizeJitter, 0, 1, 1);

LTBoundedPrimitivePropertyImplement(CGFloat, minimumDiameter, MinimumDiameter, 0, 1, 0.5);

LTBoundedPrimitivePropertyImplement(CGFloat, angleJitter, AngleJitter, 0, 1, 1);

LTBoundedPrimitivePropertyImplement(CGFloat, roundnessJitter, RoundnessJitter, 0, 1, 0);

LTBoundedPrimitivePropertyImplement(CGFloat, minimumRoundness, MinimumRoundness, 0, 1, 0.25);

@end
