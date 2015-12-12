// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

typedef lt::Interval<CGFloat> LTTestInterval;

SpecBegin(LTInterval)

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Closed, LTTestInterval::Open);
    expect(interval.min()).to.equal(0);
    expect(interval.max()).to.equal(1);
    expect(interval.minEndpointIncluded()).to.beTruthy();
    expect(interval.maxEndpointIncluded()).to.beFalsy();

    interval = LTTestInterval({-1, 2}, LTTestInterval::Closed);
    expect(interval.min()).to.equal(-1);
    expect(interval.max()).to.equal(2);
    expect(interval.minEndpointIncluded()).to.beTruthy();
    expect(interval.maxEndpointIncluded()).to.beTruthy();
  });

  it(@"should initialize correctly, independent of value order", ^{
    LTTestInterval interval({1, 0}, LTTestInterval::Closed, LTTestInterval::Open);
    expect(interval.min()).to.equal(0);
    expect(interval.max()).to.equal(1);
    expect(interval.minEndpointIncluded()).to.beTruthy();
    expect(interval.maxEndpointIncluded()).to.beFalsy();

    interval = LTTestInterval({2, -1}, LTTestInterval::Closed);
    expect(interval.min()).to.equal(-1);
    expect(interval.max()).to.equal(2);
    expect(interval.minEndpointIncluded()).to.beTruthy();
    expect(interval.maxEndpointIncluded()).to.beTruthy();
  });
});

context(@"value inclusion", ^{
  it(@"should return correct results for containment queries of an open interval", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Open);
    expect(interval.contains((CGFloat)-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });

  it(@"should return correct results for containment queries of a half-closed interval (a, b]", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Open, LTTestInterval::Closed);
    expect(interval.contains(-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });

  it(@"should return correct results for containment queries of a half-closed interval [a, b)", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Closed, LTTestInterval::Open);
    expect(interval.contains(-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });

  it(@"should return correct results for containment queries of a closed interval", ^{
    LTTestInterval interval({0, 1}, LTTestInterval::Closed);
    expect(interval.contains(-1)).to.beFalsy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)-1))).to.beFalsy();
    expect(interval.contains(0)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)0, (CGFloat)1))).to.beTruthy();
    expect(interval.contains(0.5)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)0))).to.beTruthy();
    expect(interval.contains(1)).to.beTruthy();
    expect(interval.contains(std::nextafter((CGFloat)1, (CGFloat)2))).to.beFalsy();
    expect(interval.contains(1.5)).to.beFalsy();
  });
});

SpecEnd
