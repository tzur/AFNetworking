// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorFilter.h"

#import "LTPainterPoint.h"

SpecBegin(LTTouchCollectorFilter)

__block LTPainterPoint *point = [[LTPainterPoint alloc] init];
__block id acceptFilter;
__block id rejectFilter;

beforeAll(^{
  acceptFilter = [OCMockObject mockForProtocol:@protocol(LTTouchCollectorFilter)];
  rejectFilter = [OCMockObject mockForProtocol:@protocol(LTTouchCollectorFilter)];
  [[[acceptFilter stub] andReturnValue:@YES] acceptNewPoint:OCMOCK_ANY withOldPoint:OCMOCK_ANY];
  [[[rejectFilter stub] andReturnValue:@NO] acceptNewPoint:OCMOCK_ANY withOldPoint:OCMOCK_ANY];
});

context(@"multi filter", ^{
  it(@"should raise an expception if abstract class is used", ^{
    LTTouchCollectorMultiFilter *filter = [[LTTouchCollectorMultiFilter alloc] initWithFilters:@[]];
    expect(^{
      [filter acceptNewPoint:point withOldPoint:point];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"and filter", ^{
  __block LTTouchCollectorAndFilter *filter;
  
  it(@"should accept if no filters are provided", ^{
    filter = [[LTTouchCollectorAndFilter alloc] initWithFilters:@[]];
    expect([filter acceptNewPoint:nil withOldPoint:nil]).to.beTruthy();
    expect([filter acceptNewPoint:point withOldPoint:point]).to.beTruthy();
  });
  
  it(@"should accept if all filters accept", ^{
    filter = [[LTTouchCollectorAndFilter alloc] initWithFilters:@[acceptFilter, acceptFilter]];
    expect([filter acceptNewPoint:nil withOldPoint:nil]).to.beTruthy();
    expect([filter acceptNewPoint:point withOldPoint:point]).to.beTruthy();
  });
  
  it(@"should reject if one or more filters reject", ^{
    filter = [[LTTouchCollectorAndFilter alloc] initWithFilters:@[acceptFilter, rejectFilter]];
    expect([filter acceptNewPoint:nil withOldPoint:nil]).to.beFalsy();
    expect([filter acceptNewPoint:point withOldPoint:point]).to.beFalsy();
  });
});

context(@"or filter", ^{
  __block LTTouchCollectorOrFilter *filter;

  it(@"should accept if no filters are provided", ^{
    filter = [[LTTouchCollectorOrFilter alloc] initWithFilters:@[]];
    expect([filter acceptNewPoint:nil withOldPoint:nil]).to.beTruthy();
    expect([filter acceptNewPoint:point withOldPoint:point]).to.beTruthy();
  });
  
  it(@"should accept if one or more filters accept", ^{
    filter = [[LTTouchCollectorOrFilter alloc] initWithFilters:@[acceptFilter, rejectFilter]];
    expect([filter acceptNewPoint:nil withOldPoint:nil]).to.beTruthy();
    expect([filter acceptNewPoint:point withOldPoint:point]).to.beTruthy();
  });
  
  it(@"should reject if all filters reject", ^{
    filter = [[LTTouchCollectorOrFilter alloc] initWithFilters:@[rejectFilter, rejectFilter]];
    expect([filter acceptNewPoint:nil withOldPoint:nil]).to.beFalsy();
    expect([filter acceptNewPoint:point withOldPoint:point]).to.beFalsy();
  });
});

SpecEnd
