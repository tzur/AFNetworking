// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushShapeDynamicsEffect.h"

#import <LTKit/LTRandom.h>

#import "LTRotatedRect.h"

@implementation LTBrushShapeDynamicsEffect

#pragma mark -
#pragma mark Effect
#pragma mark -

- (NSMutableArray *)dynamicRectsFromRects:(NSArray *)rects {
  LTParameterAssert(rects);
  NSMutableArray *dynamicRects = [NSMutableArray array];
  for (LTRotatedRect *rect in rects) {
    [dynamicRects addObject:[self randomRectFromRect:rect]];
  }
  return dynamicRects;
}

- (LTRotatedRect *)randomRectFromRect:(LTRotatedRect *)rect {
  CGFloat randomSizeJitter = [self.random randomDoubleBetweenMin:0 max:self.sizeJitter];
  CGSize newSize = rect.rect.size - rect.rect.size * randomSizeJitter * (1 - self.minimumDiameter);

  CGFloat randomRoundnessJitter = [self.random randomDoubleBetweenMin:0 max:self.roundnessJitter];
  newSize.height = newSize.height * (1 - randomRoundnessJitter * (1 - self.minimumRoundness));
  
  CGFloat randomAngleJitter =
      [self.random randomDoubleBetweenMin:-self.angleJitter * M_PI max:self.angleJitter * M_PI];
  CGFloat newAngle = rect.angle + randomAngleJitter;
  
  LTRotatedRect *newRect = [LTRotatedRect rectWithCenter:rect.center size:newSize angle:newAngle];
  return newRect;
}


#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, sizeJitter, SizeJitter, 0, 1, 0);
LTProperty(CGFloat, minimumDiameter, MinimumDiameter, 0, 1, 0.5);
LTProperty(CGFloat, angleJitter, AngleJitter, 0, 1, 0);
LTProperty(CGFloat, roundnessJitter, RoundnessJitter, 0, 1, 0);
LTProperty(CGFloat, minimumRoundness, MinimumRoundness, 0, 1, 0.25);

@end
