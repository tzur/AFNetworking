// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGaussianConvolutionDivider.h"

#import "LTGaussianFilterProcessor.h"

SpecBegin(LTGaussianConvolutionDivider)

it(@"should not initialize with invalid arguments", ^{
  expect(^{
    LTGaussianConvolutionDivider * __unused divider =
        [[LTGaussianConvolutionDivider alloc] initWithSigma:0 spatialUnit:1 maxFilterTaps:13
                                       gaussianEnergyFactor:1];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    LTGaussianConvolutionDivider * __unused divider =
        [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:-1 maxFilterTaps:13
                                       gaussianEnergyFactor:1];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    LTGaussianConvolutionDivider * __unused divider =
        [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:1 maxFilterTaps:13
                                       gaussianEnergyFactor:-1];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    LTGaussianConvolutionDivider * __unused divider =
        [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:1 maxFilterTaps:13
                                       gaussianEnergyFactor:5];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    LTGaussianConvolutionDivider * __unused divider =
        [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:1 maxFilterTaps:2
                                       gaussianEnergyFactor:1];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    LTGaussianConvolutionDivider * __unused divider =
        [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:1 maxFilterTaps:20
                                       gaussianEnergyFactor:1];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should give correct results for a trivial case", ^{
  LTGaussianConvolutionDivider *divider =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:1 maxFilterTaps:13
                                     gaussianEnergyFactor:1];
  expect(divider.iterationsRequired).to.equal(1);
  expect(divider.iterationSigma).to.equal(1);
  expect(divider.numberOfFilterTaps).to.equal(3);
});

it(@"should increase number of iterations required as sigma increases to a high extent", ^{
  LTGaussianConvolutionDivider *divider1 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:1 maxFilterTaps:11
                                     gaussianEnergyFactor:1];
  LTGaussianConvolutionDivider *divider2 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:200 spatialUnit:1 maxFilterTaps:11
                                     gaussianEnergyFactor:1];
  LTGaussianConvolutionDivider *divider3 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:300 spatialUnit:1 maxFilterTaps:11
                                     gaussianEnergyFactor:1];
  expect(divider2.iterationsRequired).to.beGreaterThan(divider1.iterationsRequired);
  expect(divider3.iterationsRequired).to.beGreaterThan(divider2.iterationsRequired);
});

it(@"should match when sigma and spatialUnit are scaled together", ^{
  LTGaussianConvolutionDivider *divider1 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:1 spatialUnit:10 maxFilterTaps:13
                                     gaussianEnergyFactor:3];
  LTGaussianConvolutionDivider *divider2 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:10 spatialUnit:100 maxFilterTaps:13
                                     gaussianEnergyFactor:3];
  expect(divider1.iterationsRequired).toNot.equal(0);
  expect(divider1.numberOfFilterTaps).toNot.equal(0);

  expect(divider1.iterationsRequired).to.equal(divider2.iterationsRequired);
  expect(divider1.numberOfFilterTaps).to.equal(divider2.numberOfFilterTaps);
});

it(@"should never make iterationSigma exceed the maxSigmaPerIteration", ^{
  LTGaussianConvolutionDivider *divider1 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:420 spatialUnit:41 maxFilterTaps:13
                                     gaussianEnergyFactor:0.2];
  expect(divider1.iterationSigma).to.beLessThanOrEqualTo(divider1.maxSigmaPerIteration);

  LTGaussianConvolutionDivider *divider2 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:0.2 spatialUnit:431 maxFilterTaps:13
                                     gaussianEnergyFactor:0.332];
  expect(divider2.iterationSigma).to.beLessThanOrEqualTo(divider2.maxSigmaPerIteration);

  LTGaussianConvolutionDivider *divider3 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:420 spatialUnit:1 maxFilterTaps:13
                                     gaussianEnergyFactor:3];
  expect(divider3.iterationSigma).to.beLessThanOrEqualTo(divider3.maxSigmaPerIteration);
});

it(@"should never exceed LTGaussianFilterProcessor taps limitation", ^{
  LTGaussianConvolutionDivider *divider1 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:420 spatialUnit:3 maxFilterTaps:13
                                     gaussianEnergyFactor:0.2];
  expect(divider1.numberOfFilterTaps).to.
      beLessThanOrEqualTo([LTGaussianFilterProcessor maxNumberOfFilterTaps]);


  LTGaussianConvolutionDivider *divider2 =
      [[LTGaussianConvolutionDivider alloc] initWithSigma:0.23 spatialUnit:0.001 maxFilterTaps:13
                                     gaussianEnergyFactor:3];
  expect(divider2.numberOfFilterTaps).to.
      beLessThanOrEqualTo([LTGaussianFilterProcessor maxNumberOfFilterTaps]);
});

SpecEnd
