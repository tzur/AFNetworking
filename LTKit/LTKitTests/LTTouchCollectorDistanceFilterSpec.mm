// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorDistanceFilter.h"

#import "LTPainterPoint.h"

SpecBegin(LTTouchCollectorDistanceFilter)

__block LTTouchCollectorDistanceFilter *filter;
__block LTPainterPoint *point0;
__block LTPainterPoint *point1;

beforeEach(^{
  point0 = [[LTPainterPoint alloc] init];
  point1 = [[LTPainterPoint alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize with a valid distance", ^{
    expect(^{
      filter = [[LTTouchCollectorDistanceFilter alloc] initWithType:LTTouchCollectorDistanceScreen
                                                    minimalDistance:0];
      filter = [[LTTouchCollectorDistanceFilter alloc] initWithType:LTTouchCollectorDistanceScreen
                                                    minimalDistance:FLT_EPSILON];
    }).notTo.raiseAny();
  });
  
  it(@"should raise an exception when initialized with a negative distance", ^{
    expect(^{
      filter = [[LTTouchCollectorDistanceFilter alloc] initWithType:LTTouchCollectorDistanceScreen
                                                    minimalDistance:-FLT_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"filtering according to screen distance", ^{
  const CGFloat kThreshold = std::sqrt(2.0);
  
  beforeEach(^{
    filter = [LTTouchCollectorDistanceFilter filterWithMinimalScreenDistance:kThreshold];
  });
  
  it(@"should accept if screen distance above threshold", ^{
    point0.screenPosition = CGPointZero;
    point1.screenPosition = CGPointMake(1 + FLT_EPSILON, 1 + FLT_EPSILON);
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beTruthy();
    expect([filter acceptNewPoint:point0 withOldPoint:point1]).to.beTruthy();
  });
  
  it(@"should reject if screen distance is lower or equal to threshold", ^{
    point0.screenPosition = CGPointZero;
    point1.screenPosition = CGPointMake(1, 1);
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beFalsy();
    expect([filter acceptNewPoint:point0 withOldPoint:point0]).to.beFalsy();

    point1.screenPosition = CGPointMake(1 - FLT_EPSILON, 1 - FLT_EPSILON);
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beFalsy();
    expect([filter acceptNewPoint:point0 withOldPoint:point0]).to.beFalsy();
  });
});

context(@"filtering according to content distance", ^{
  const CGFloat kThreshold = std::sqrt(2.0);
  
  beforeEach(^{
    filter = [LTTouchCollectorDistanceFilter filterWithMinimalContentDistance:kThreshold];
  });
  
  it(@"should accept if content distance above threshold", ^{
    point0.contentPosition = CGPointZero;
    point1.contentPosition = CGPointMake(1 + FLT_EPSILON, 1 + FLT_EPSILON);
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beTruthy();
    expect([filter acceptNewPoint:point0 withOldPoint:point1]).to.beTruthy();
  });
  
  it(@"should reject if content distance is lower or equal to threshold", ^{
    point0.contentPosition = CGPointZero;
    point1.contentPosition = CGPointMake(1, 1);
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beFalsy();
    expect([filter acceptNewPoint:point0 withOldPoint:point0]).to.beFalsy();
    
    point1.contentPosition = CGPointMake(1 - FLT_EPSILON, 1 - FLT_EPSILON);
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beFalsy();
    expect([filter acceptNewPoint:point0 withOldPoint:point0]).to.beFalsy();
  });
});

SpecEnd
