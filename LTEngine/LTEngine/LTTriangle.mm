// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTriangle.h"

#import "LTGeometry.h"

@interface LTTriangle ()

@property (nonatomic) LTTriangleCorners corners;

@end

@implementation LTTriangle

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCorners:(const LTTriangleCorners &)corners {
  if (self = [super init]) {
    self.corners = corners;
    CGPoint direction = self.corners[2] - self.corners[1];
    BOOL cornersAreGivenInClockwiseOrientation =
        LTPointLocationRelativeToRay(self.corners[0], self.corners[1], direction) ==
        LTPointLocationRightOfRay;
    if (!cornersAreGivenInClockwiseOrientation) {
      self.corners = LTTriangleCorners{{self.corners[2], self.corners[1], self.corners[0]}};
    }
  }
  return self;
}

#pragma mark -
#pragma mark Point inclusion
#pragma mark -

- (BOOL)containsPoint:(CGPoint)point {
  NSUInteger size = self.corners.size();
  for (NSUInteger i = 0; i < size; i++) {
    CGPoint origin = self.corners[i];
    CGPoint direction = self.corners[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(point, origin, direction) == LTPointLocationLeftOfRay) {
      return NO;
    }
  }
  return YES;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGPoint)v0 {
  return self.corners[0];
}

- (CGPoint)v1 {
  return self.corners[1];
}

- (CGPoint)v2 {
  return self.corners[2];
}

@end
