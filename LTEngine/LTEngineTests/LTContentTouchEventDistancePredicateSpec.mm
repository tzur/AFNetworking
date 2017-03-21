// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventDistancePredicate.h"

#import "LTContentTouchEvent.h"

SpecBegin(LTContentTouchEventDistancePredicate)

__block id<LTContentTouchEvent> event0;
__block id<LTContentTouchEvent> event1;

beforeEach(^{
  event0 = OCMProtocolMock(@protocol(LTContentTouchEvent));
  event1 = OCMProtocolMock(@protocol(LTContentTouchEvent));
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentTouchEventDistancePredicate *predicate =
        [[LTContentTouchEventDistancePredicate alloc]
         initWithType:LTContentTouchEventDistancePredicateTypeView minimumDistance:1];

    expect(predicate.type).to.equal(LTContentTouchEventDistancePredicateTypeView);
    expect(predicate.minimumDistance).to.equal(1);
  });

  it(@"should initialize view distance predicate using factory method", ^{
    LTContentTouchEventDistancePredicate *predicate =
        [LTContentTouchEventDistancePredicate predicateWithMinimumViewDistance:1];

    expect(predicate.type).to.equal(LTContentTouchEventDistancePredicateTypeView);
    expect(predicate.minimumDistance).to.equal(1);
  });

  it(@"should initialize content distance predicate using factory method", ^{
    LTContentTouchEventDistancePredicate *predicate =
        [LTContentTouchEventDistancePredicate predicateWithMinimumContentDistance:1];

    expect(predicate.type).to.equal(LTContentTouchEventDistancePredicateTypeContent);
    expect(predicate.minimumDistance).to.equal(1);
  });

  it(@"should raise when initialized with negative minimum distance", ^{
    expect(^{
      LTContentTouchEventDistancePredicate __unused *predicate =
          [[LTContentTouchEventDistancePredicate alloc]
           initWithType:LTContentTouchEventDistancePredicateTypeView minimumDistance:-FLT_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"predicating", ^{
  const CGFloat kThreshold = std::sqrt(2.0);

  context(@"predicating with distance between view locations", ^{
    __block LTContentTouchEventDistancePredicate *predicate;

    beforeEach(^{
      predicate =
          [LTContentTouchEventDistancePredicate predicateWithMinimumViewDistance:kThreshold];
    });

    it(@"should accept if distance is greater than threshold", ^{
      OCMStub([event0 viewLocation]).andReturn(CGPointZero);
      OCMStub([event1 viewLocation]).andReturn(CGPointMake(1 + FLT_EPSILON, 1 + FLT_EPSILON));
      expect([predicate isValidEvent:event1 givenEvent:event0]).to.beTruthy();
      expect([predicate isValidEvent:event0 givenEvent:event1]).to.beTruthy();
    });

    it(@"should reject if distance is less than threshold", ^{
      OCMStub([event0 viewLocation]).andReturn(CGPointZero);
      OCMStub([event1 viewLocation]).andReturn(CGPointMake(1 - FLT_EPSILON, 1 - FLT_EPSILON));
      expect([predicate isValidEvent:event1 givenEvent:event0]).to.beFalsy();
      expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
    });

    it(@"should reject if distance is equal to threshold", ^{
      OCMStub([event0 viewLocation]).andReturn(CGPointZero);
      OCMStub([event1 viewLocation]).andReturn(CGPointMake(1, 1));
      expect([predicate isValidEvent:event1 givenEvent:event0]).to.beFalsy();
      expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
    });
  });

  context(@"predicating with distance between content locations", ^{
    __block LTContentTouchEventDistancePredicate *predicate;

    beforeEach(^{
      predicate =
          [LTContentTouchEventDistancePredicate predicateWithMinimumContentDistance:kThreshold];
    });

    it(@"should accept if distance is greater than threshold", ^{
      OCMStub([event0 contentLocation]).andReturn(CGPointZero);
      OCMStub([event1 contentLocation]).andReturn(CGPointMake(1 + FLT_EPSILON, 1 + FLT_EPSILON));
      expect([predicate isValidEvent:event1 givenEvent:event0]).to.beTruthy();
      expect([predicate isValidEvent:event0 givenEvent:event1]).to.beTruthy();
    });

    it(@"should reject if distance is less than threshold", ^{
      OCMStub([event0 contentLocation]).andReturn(CGPointZero);
      OCMStub([event1 contentLocation]).andReturn(CGPointMake(1 - FLT_EPSILON, 1 - FLT_EPSILON));
      expect([predicate isValidEvent:event1 givenEvent:event0]).to.beFalsy();
      expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
    });

    it(@"should reject if distance is equal to threshold", ^{
      OCMStub([event0 contentLocation]).andReturn(CGPointZero);
      OCMStub([event1 contentLocation]).andReturn(CGPointMake(1, 1));
      expect([predicate isValidEvent:event1 givenEvent:event0]).to.beFalsy();
      expect([predicate isValidEvent:event0 givenEvent:event1]).to.beFalsy();
    });
  });
});

SpecEnd
