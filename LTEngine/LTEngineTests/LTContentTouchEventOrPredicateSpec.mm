// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventOrPredicate.h"

SpecBegin(LTContentTouchEventOrPredicate)

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
    LTContentTouchEventOrPredicate *predicate =
        [[LTContentTouchEventOrPredicate alloc]
         initWithPredicates:@[acceptPredicate, rejectPredicate]];
    expect(predicate.predicates).to.equal(@[acceptPredicate, rejectPredicate]);
  });

  it(@"should create predicate correctly using factory method", ^{
    LTContentTouchEventOrPredicate *predicate =
        [LTContentTouchEventOrPredicate
         predicateWithPredicates:@[acceptPredicate, rejectPredicate]];
    expect(predicate.predicates).to.equal(@[acceptPredicate, rejectPredicate]);
  });
});

context(@"predicating", ^{
  it(@"should reject if no predicates are provided", ^{
    LTContentTouchEventOrPredicate *predicate =
        [LTContentTouchEventOrPredicate predicateWithPredicates:@[]];
    expect([predicate isValidEvent:event givenEvent:event]).to.beFalsy();
  });

  it(@"should accept if one or more predicates accept", ^{
    NSArray<id<LTContentTouchEventPredicate>> *predicates =
        @[rejectPredicate, acceptPredicate, rejectPredicate];
    LTContentTouchEventOrPredicate *predicate =
        [LTContentTouchEventOrPredicate predicateWithPredicates:predicates];
    expect([predicate isValidEvent:event givenEvent:event]).to.beTruthy();
  });

  it(@"should reject if all predicates reject", ^{
    NSArray<id<LTContentTouchEventPredicate>> *predicates =
        @[rejectPredicate, rejectPredicate, rejectPredicate];
    LTContentTouchEventOrPredicate *predicate =
        [LTContentTouchEventOrPredicate predicateWithPredicates:predicates];
    expect([predicate isValidEvent:event givenEvent:event]).to.beFalsy();
  });
});

SpecEnd
