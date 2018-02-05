// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSValue+LTInterval.h"

SpecBegin(NSValue_LTInterval)

context(@"CGFloat intervals", ^{
  __block lt::Interval<CGFloat> interval;
  __block NSValue *value;

  beforeEach(^{
    interval = lt::Interval<CGFloat>({1, 2}, lt::Interval<CGFloat>::Open,
                                     lt::Interval<CGFloat>::Closed);
    value = [NSValue valueWithLTCGFloatInterval:interval];
  });

  it(@"should box a given CGFloat interval", ^{
    expect(value).toNot.beNil();
  });

  it(@"should box a given boxed CGFloat interval", ^{
    expect([value LTCGFloatIntervalValue] == interval).to.beTruthy();
  });
});

context(@"NSInteger intervals", ^{
  __block lt::Interval<NSInteger> interval;
  __block NSValue *value;

  beforeEach(^{
    interval = lt::Interval<NSInteger>({1, 2}, lt::Interval<NSInteger>::Open,
                                       lt::Interval<NSInteger>::Closed);
    value = [NSValue valueWithLTNSIntegerInterval:interval];
  });

  it(@"should box a given NSInteger interval", ^{
    expect(value).toNot.beNil();
  });

  it(@"should box a given boxed NSInteger interval", ^{
    expect([value LTNSIntegerIntervalValue] == interval).to.beTruthy();
  });
});

context(@"NSUInteger intervals", ^{
  __block lt::Interval<NSUInteger> interval;
  __block NSValue *value;

  beforeEach(^{
    interval = lt::Interval<NSUInteger>({1, 2}, lt::Interval<NSUInteger>::Open,
                                        lt::Interval<NSUInteger>::Closed);
    value = [NSValue valueWithLTNSUIntegerInterval:interval];
  });

  it(@"should box a given NSUInteger interval", ^{
    expect(value).toNot.beNil();
  });

  it(@"should box a given boxed NSUInteger interval", ^{
    expect([value LTNSUIntegerIntervalValue] == interval).to.beTruthy();
  });
});

SpecEnd
