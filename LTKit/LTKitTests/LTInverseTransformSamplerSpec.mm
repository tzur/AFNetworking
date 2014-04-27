// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInverseTransformSampler.h"

SpecBegin(LTInverseTransformSampler)

context(@"initialization", ^{
  it(@"should not initialize on empty distribution", ^{
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:Floats()];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize on all zero distribution", ^{
    Floats frequencies = {0.f, 0.f, 0.f};
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize on distribution with negative value", ^{
    Floats frequencies = {2.f, -1.f, 0.f};
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with a given distribution", ^{
    Floats frequencies = {5.f, 6.f, 1.f};
    expect(^{
      LTInverseTransformSampler __unused *sampler =
          [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
    }).toNot.raiseAny();
  });
});

context(@"sampling", ^{
  const NSUInteger kSamples = 100;

  it(@"should sample correctly from a single value distribution", ^{
    Floats frequencies = {42.f};

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
    Floats frequencies = {0.f, 0.f, 42.f, 0.f, 0.f};

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

    id<LTDistributionSampler> sampler = [factory samplerWithFrequencies:{1.f, 2.f}];

    expect(sampler).to.beKindOf([LTInverseTransformSampler class]);
  });
});

SpecEnd
