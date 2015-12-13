// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTFloatSetExamples.h"

#import "LTFloatSet.h"

NSString * const kLTFloatSetExamples = @"LTFloatSetExamples";
NSString * const kLTFloatSetObject = @"LTFloatSetObject";
NSString * const kLTFloatSetInterval = @"LTFloatSetInterval";
NSString * const kLTFloatSetExpectedValues = @"LTFloatSetExpectedValues";

SharedExamplesBegin(LTFloatSet)

static const CGFloat kEpsilon = 1e-4;

sharedExamplesFor(kLTFloatSetExamples, ^(NSDictionary *data) {
  __block id<LTFloatSet> set;
  __block lt::Interval<CGFloat> interval;
  __block NSArray<NSNumber *> *expectedValues;

  beforeEach(^{
    set = data[kLTFloatSetObject];
    [data[kLTFloatSetInterval] getValue:&interval];
    expectedValues = data[kLTFloatSetExpectedValues];
  });

  it(@"should return the correct discrete values", ^{
    CGFloats values = [set discreteValuesInInterval:interval];
    expect(values.size()).to.equal(expectedValues.count);
    [expectedValues enumerateObjectsUsingBlock:^(NSNumber *expectedValue, NSUInteger index,
                                                 BOOL *) {
      expect(values[index]).to.beCloseToWithin([expectedValue CGFloatValue], kEpsilon);
    }];
  });
});

SharedExamplesEnd
