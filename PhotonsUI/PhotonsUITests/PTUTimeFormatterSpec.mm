// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import "PTUTimeFormatter.h"

SpecBegin(PTUTimeFormatter)

__block PTUTimeFormatter *timeFormatter;

beforeEach(^{
  timeFormatter = [[PTUTimeFormatter alloc] init];
});

it(@"should format CMTime correctly", ^{
  CMTime time = kCMTimeInvalid;
  expect([timeFormatter timeStringForTime:time]).to.equal(@"00:00");

  time = kCMTimeZero;
  expect([timeFormatter timeStringForTime:time]).to.equal(@"00:00");

  time = CMTimeMake(50, 1);
  expect([timeFormatter timeStringForTime:time]).to.equal(@"00:50");

  time = CMTimeMake(160, 1);
  expect([timeFormatter timeStringForTime:time]).to.equal(@"02:40");

  time = CMTimeMake(600, 1);
  expect([timeFormatter timeStringForTime:time]).to.equal(@"10:00");

  time = CMTimeMake(3600, 1);
  expect([timeFormatter timeStringForTime:time]).to.equal(@"01:00:00");

  time = CMTimeMake(5640, 1);
  expect([timeFormatter timeStringForTime:time]).to.equal(@"01:34:00");

  time = CMTimeMake(36500, 1);
  expect([timeFormatter timeStringForTime:time]).to.equal(@"10:08:20");
});

it(@"should format NSTimeInterval correctly", ^{
  expect([timeFormatter timeStringForTimeInterval:0]).to.equal(@"00:00");

  expect([timeFormatter timeStringForTimeInterval:50]).to.equal(@"00:50");

  expect([timeFormatter timeStringForTimeInterval:160]).to.equal(@"02:40");

  expect([timeFormatter timeStringForTimeInterval:600]).to.equal(@"10:00");

  expect([timeFormatter timeStringForTimeInterval:3600]).to.equal(@"01:00:00");

  expect([timeFormatter timeStringForTimeInterval:5640]).to.equal(@"01:34:00");

  expect([timeFormatter timeStringForTimeInterval:36500]).to.equal(@"10:08:20");
});

SpecEnd
