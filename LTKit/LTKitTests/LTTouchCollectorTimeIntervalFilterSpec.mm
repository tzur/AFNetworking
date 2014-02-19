// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorTimeIntervalFilter.h"

#import "LTPainterPoint.h"

SpecBegin(LTTouchCollectorTimeIntervalFilter)
__block LTTouchCollectorTimeIntervalFilter *filter;
__block LTPainterPoint *point0;
__block LTPainterPoint *point1;

beforeEach(^{
  point0 = [[LTPainterPoint alloc] init];
  point1 = [[LTPainterPoint alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize with a valid distance", ^{
    expect(^{
      filter = [[LTTouchCollectorTimeIntervalFilter alloc] initWithMinimalTimeInterval:0];
      filter = [[LTTouchCollectorTimeIntervalFilter alloc] initWithMinimalTimeInterval:FLT_EPSILON];
    }).notTo.raiseAny();
  });
  
  it(@"should raise an exception when initialized with a negative distance", ^{
    expect(^{
      filter =
          [[LTTouchCollectorTimeIntervalFilter alloc] initWithMinimalTimeInterval:-FLT_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"filtering", ^{
  const CFTimeInterval kThreshold = 1.0;
  
  beforeEach(^{
    filter = [LTTouchCollectorTimeIntervalFilter filterWithMinimalTimeInterval:kThreshold];
  });
  
  it(@"should accept if time difference is above threshold", ^{
    point0.timestamp = CACurrentMediaTime();
    point1.timestamp = point0.timestamp + kThreshold + DBL_EPSILON;
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beTruthy;
    expect([filter acceptNewPoint:point0 withOldPoint:point1]).to.beFalsy;
  });
  
  it(@"should reject if time difference is lower or equal to threshold", ^{
    point0.timestamp = CACurrentMediaTime();
    point1.timestamp = point0.timestamp + kThreshold;
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beFalsy;
    expect([filter acceptNewPoint:point0 withOldPoint:point0]).to.beFalsy;
    
    point1.timestamp = point0.timestamp + kThreshold - DBL_EPSILON;
    expect([filter acceptNewPoint:point1 withOldPoint:point0]).to.beFalsy;
    expect([filter acceptNewPoint:point0 withOldPoint:point0]).to.beFalsy;
  });
});

SpecEnd
