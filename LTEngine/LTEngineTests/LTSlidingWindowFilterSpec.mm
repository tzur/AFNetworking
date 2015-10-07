// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSlidingWindowFilter.h"

SpecBegin(LTSlidingWindowFilter)

__block LTSlidingWindowFilter *filter;

static const CGFloat kEpsilon = 1e-6;

afterEach(^{
  filter = nil;
});

context(@"initializiation", ^{
  it(@"should initialize with the given kernel", ^{
    expect(^{
      filter = [[LTSlidingWindowFilter alloc] initWithKernel:{1, 2, 3, 4}];
    }).notTo.raiseAny();
  });
});

context(@"filtering", ^{
  beforeEach(^{
    filter = [[LTSlidingWindowFilter alloc] initWithKernel:{1, 2, 4}];
  });

  it(@"should filter correctly", ^{
    CGFloats result;
    result.push_back([filter pushValueAndFilter:0]);
    result.push_back([filter pushValueAndFilter:1]);
    result.push_back([filter pushValueAndFilter:0]);
    result.push_back([filter pushValueAndFilter:0]);

    CGFloats expected({0, 4, 2, 1});
    expect(result.size()).to.equal(expected.size());
    for (NSUInteger i = 0; i < expected.size(); ++i) {
      expect(result[i]).to.beCloseToWithin(expected[i], kEpsilon);
    }
  });

  it(@"should slide window by pushing out the least recently added value", ^{
    expect([filter pushValueAndFilter:1]).notTo.equal(0);
    expect([filter pushValueAndFilter:0]).notTo.equal(0);
    expect([filter pushValueAndFilter:0]).notTo.equal(0);
    expect([filter pushValueAndFilter:0]).to.equal(0);
  });

  it(@"should fill with the initial value when window is empty", ^{
    CGFloats result;
    result.push_back([filter pushValueAndFilter:1]);
    result.push_back([filter pushValueAndFilter:0]);
    result.push_back([filter pushValueAndFilter:0]);
    result.push_back([filter pushValueAndFilter:0]);

    CGFloats expected({7, 3, 1, 0});
    expect(result.size()).to.equal(expected.size());
    for (NSUInteger i = 0; i < expected.size(); ++i) {
      expect(result[i]).to.beCloseToWithin(expected[i], kEpsilon);
    }
  });

  it(@"should clear window", ^{
    expect([filter pushValueAndFilter:1]).to.equal(7);

    [filter clear];
    CGFloats result;
    result.push_back([filter pushValueAndFilter:2]);
    result.push_back([filter pushValueAndFilter:0]);
    result.push_back([filter pushValueAndFilter:0]);
    result.push_back([filter pushValueAndFilter:0]);

    CGFloats expected({14, 6, 2, 0});
    expect(result.size()).to.equal(expected.size());
    for (NSUInteger i = 0; i < expected.size(); ++i) {
      expect(result[i]).to.beCloseToWithin(expected[i], kEpsilon);
    }
  });
});

SpecEnd
