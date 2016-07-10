// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventTimeIntervalPredicate.h"

#import "LTContentTouchEvent.h"

SpecBegin(LTContentTouchEventTimeIntervalPredicate)

__block id<LTContentTouchEvent> event0;
__block id<LTContentTouchEvent> event1;

beforeEach(^{
  event0 = OCMProtocolMock(@protocol(LTContentTouchEvent));
  event1 = OCMProtocolMock(@protocol(LTContentTouchEvent));
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentTouchEventTimeIntervalPredicate *predicate =
        [[LTContentTouchEventTimeIntervalPredicate alloc] initWithMinimumTimeInterval:1];

    expect(predicate.minimumInterval).to.equal(1);
  });

  it(@"should initialize correctly using factory method", ^{
    LTContentTouchEventTimeIntervalPredicate *predicate =
        [LTContentTouchEventTimeIntervalPredicate predicateWithMinimumTimeInterval:1];

    expect(predicate.minimumInterval).to.equal(1);
  });

  it(@"should raise when initialized with negative minimum interval", ^{
    expect(^{
      LTContentTouchEventTimeIntervalPredicate __unused *predicate =
          [[LTContentTouchEventTimeIntervalPredicate alloc]
           initWithMinimumTimeInterval:-FLT_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"predicating", ^{
  const NSTimeInterval kThreshold = std::pow(2.0, -4.0);
  const NSTimeInterval kTimestamp = 1.2e5;

  __block LTContentTouchEventTimeIntervalPredicate *predicate;

  beforeEach(^{
    predicate =
        [LTContentTouchEventTimeIntervalPredicate predicateWithMinimumTimeInterval:kThreshold];
  });

  it(@"should accept if time difference is greater than threshold", ^{
    OCMStub([event0 timestamp]).andReturn(kTimestamp);
    OCMStub([event1 timestamp]).andReturn(kTimestamp + kThreshold + FLT_EPSILON);
    expect([predicate isValidEvent:event1 givenEvent:event0]).to.beTruthy();
    expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
  });

  it(@"should reject if time difference is less than threshold", ^{
    OCMStub([event0 timestamp]).andReturn(kTimestamp);
    OCMStub([event1 timestamp]).andReturn(kTimestamp + kThreshold - FLT_EPSILON);
    expect([predicate isValidEvent:event1 givenEvent:event0]).to.beFalsy();
    expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
  });

  it(@"should reject if time difference is equal to threshold", ^{
    OCMStub([event0 timestamp]).andReturn(kTimestamp);
    OCMStub([event1 timestamp]).andReturn(kTimestamp + kThreshold);
    expect([predicate isValidEvent:event1 givenEvent:event0]).to.beFalsy();
    expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
  });
});

SpecEnd
