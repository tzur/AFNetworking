// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInverseTransformSampler.h"

SpecBegin(LTInverseTransformSampler)

context(@"initialization", ^{
  it(@"should not initialize on empty distribution", ^{
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:[NSArray array]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize on all zero distribution", ^{
    NSArray *frequencies = @[@0, @0, @0];
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize on distribution with negative value", ^{
    NSArray *frequencies = @[@1, @-1, @0];
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with a given distribution", ^{
    NSArray *frequencies = @[@5, @6, @1];
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    }).toNot.raiseAny();
  });
});

context(@"sampling", ^{
  const NSUInteger kSamples = 100;

  it(@"should sample correctly from a single value distribution", ^{
    NSArray *frequencies = @[@42];

    LTInverseTransformSampler *sampler =
        [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    NSArray *samples = [sampler sample:kSamples];

    NSMutableArray *expected = [NSMutableArray array];
    for (NSUInteger i = 0; i < kSamples; ++i) {
      [expected addObject:@0];
    }

    expect(samples).to.equal(expected);
  });

  it(@"should sample correctly from a degenerate distribution", ^{
    NSArray *frequencies = @[@0, @0, @42, @0, @0];

    LTInverseTransformSampler *sampler =
        [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    NSArray *samples = [sampler sample:kSamples];

    NSMutableArray *expected = [NSMutableArray array];
    for (NSUInteger i = 0; i < kSamples; ++i) {
      [expected addObject:@2];
    }

    expect(samples).to.equal(expected);
  });

  // TODO:(yaron) add more tests once there's a random generator class.
});

context(@"factory", ^{
  it(@"should return inverse transform sampler", ^{
    LTInverseTransformSamplerFactory *factory = [[LTInverseTransformSamplerFactory alloc] init];

    id<LTDistributionSampler> sampler = [factory samplerWithFrequencies:@[@1, @2]];

    expect(sampler).to.beKindOf([LTInverseTransformSampler class]);
  });
});

SpecEnd
