// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventAndPredicate.h"

SpecBegin(LTContentTouchEventAndPredicate)

__block id<LTContentTouchEvent> event;
__block id<LTContentTouchEventPredicate> acceptPredicate;
__block id<LTContentTouchEventPredicate> rejectPredicate;

beforeEach(^{
  event = OCMProtocolMock(@protocol(LTContentTouchEvent));
  acceptPredicate = OCMProtocolMock(@protocol(LTContentTouchEventPredicate));
  rejectPredicate = OCMProtocolMock(@protocol(LTContentTouchEventPredicate));
  OCMStub([acceptPredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(YES);
  OCMStub([rejectPredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentTouchEventAndPredicate *predicate =
        [[LTContentTouchEventAndPredicate alloc]
         initWithPredicates:@[acceptPredicate, rejectPredicate]];
    expect(predicate.predicates).to.equal(@[acceptPredicate, rejectPredicate]);
  });

  it(@"should create predicate correctly using factory method", ^{
    LTContentTouchEventAndPredicate *predicate =
        [LTContentTouchEventAndPredicate
         predicateWithPredicates:@[acceptPredicate, rejectPredicate]];
    expect(predicate.predicates).to.equal(@[acceptPredicate, rejectPredicate]);
  });
});

context(@"predicating", ^{
  it(@"should accept if no predicates are provided", ^{
    LTContentTouchEventAndPredicate *predicate =
        [LTContentTouchEventAndPredicate predicateWithPredicates:@[]];
    expect([predicate isValidEvent:event givenEvent:event]).to.beTruthy();
  });

  it(@"should accept if all predicates accept", ^{
    NSArray<id<LTContentTouchEventPredicate>> *predicates =
        @[acceptPredicate, acceptPredicate, acceptPredicate];
    LTContentTouchEventAndPredicate *predicate =
        [LTContentTouchEventAndPredicate predicateWithPredicates:predicates];
    expect([predicate isValidEvent:event givenEvent:event]).to.beTruthy();
  });

  it(@"should reject if one or more predicates reject", ^{
    NSArray<id<LTContentTouchEventPredicate>> *predicates =
        @[acceptPredicate, rejectPredicate, acceptPredicate];
    LTContentTouchEventAndPredicate *predicate =
        [LTContentTouchEventAndPredicate predicateWithPredicates:predicates];
    expect([predicate isValidEvent:event givenEvent:event]).to.beFalsy();
  });
});

SpecEnd
