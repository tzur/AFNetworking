// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSValueTransformer+Bazaar.h"

SpecBegin(NSValueTransformer_Bazaar)

context(@"time interval since 1970 transformer", ^{
  __block NSValueTransformer *transformer;
  __block NSTimeInterval timeInterval;
  __block NSDate *dateTime;

  beforeEach(^{
    transformer = [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
    timeInterval = 1337;
    dateTime = [NSDate dateWithTimeIntervalSince1970:1337];
  });

  it(@"should indicate that it supports reverse transformation", ^{
    expect([[transformer class] allowsReverseTransformation]).to.beTruthy();
  });

  it(@"should correctly transform an NSTimeInterval to NSDate", ^{
    NSDate *transformedDateTime = [transformer transformedValue:@(timeInterval)];
    expect(transformedDateTime).to.equal(dateTime);
  });

  it(@"should return nil if given nil", ^{
    expect([transformer transformedValue:nil]).to.beNil();
    expect([transformer reverseTransformedValue:nil]).to.beNil();
  });

  it(@"should correctly transform an NSDate to NSTimeInterval", ^{
    NSTimeInterval transformedTimeInterval =
        [[transformer reverseTransformedValue:dateTime] doubleValue];
    expect(transformedTimeInterval).to.beCloseToWithin(timeInterval, DBL_EPSILON);
  });
});

SpecEnd
