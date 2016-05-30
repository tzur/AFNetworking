// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTConsistentGaussianFilterProcessor.h"

#import "LTBicubicResizeProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTConsistentGaussianFilterProcessor)

context(@"compare 2D delta response", ^{
  it(@"should match closely between blur(imresize(I,1/3)) and imresize(blur(I),1/3)", ^{
    // 3x3 delta function sum is a 2d rect function.
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class],
        @"ConsistentGaussianFilter3x3Delta90x60.png")];
    LTTexture *minifiedInput = [LTTexture byteRGBATextureWithSize:input.size / 3];
    [[[LTBicubicResizeProcessor alloc] initWithInput:input output:minifiedInput] process];
    LTTexture *outputOfInput = [LTTexture textureWithPropertiesOf:input];
    LTTexture *outputOfMinifiedInput = [LTTexture textureWithPropertiesOf:minifiedInput];
    LTTexture *minifiedOutputOfInput = [LTTexture textureWithPropertiesOf:minifiedInput];

    const CGFloat kSigma = 0.04;
    const CGFloat kGaussianEnergyFactor = kGaussianEnergyFactor99Percent;
    [[[LTConsistentGaussianFilterProcessor alloc] initWithInput:input output:outputOfInput
                                                         sigma:kSigma
                                          gaussianEnergyFactor:kGaussianEnergyFactor] process];

    [[[LTConsistentGaussianFilterProcessor alloc] initWithInput:minifiedInput
                                                         output:outputOfMinifiedInput
                                                          sigma:kSigma
                                           gaussianEnergyFactor:kGaussianEnergyFactor] process];

    [[[LTBicubicResizeProcessor alloc] initWithInput:outputOfInput
                                              output:minifiedOutputOfInput] process];
    // It shouldn't equal exactly since mathematically the operations are different but should
    // exibit some correspondence.
    expect($([minifiedOutputOfInput image])).to.
        beCloseToMatWithin($([outputOfMinifiedInput image]), 2);
  });
});

context(@"compare 2d on a real image", ^{
  it(@"should produce a similar perceivable result for the same image of different sizes", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class],
        @"ConsistentGaussianFilterLena384.png")];
    LTTexture *minifiedInput = [LTTexture byteRGBATextureWithSize:input.size / 3];
    [[[LTBicubicResizeProcessor alloc] initWithInput:input output:minifiedInput] process];
    LTTexture *outputOfInput = [LTTexture textureWithPropertiesOf:input];
    LTTexture *outputOfMinifiedInput = [LTTexture textureWithPropertiesOf:minifiedInput];
    LTTexture *minifiedOutputOfInput = [LTTexture textureWithPropertiesOf:minifiedInput];
    const CGFloat kSigma = 0.009;
    const CGFloat kGaussianEnergyFactor = kGaussianEnergyFactor99Percent;

    [[[LTConsistentGaussianFilterProcessor alloc] initWithInput:input output:outputOfInput
                                                          sigma:kSigma
                                           gaussianEnergyFactor:kGaussianEnergyFactor] process];

    [[[LTConsistentGaussianFilterProcessor alloc] initWithInput:minifiedInput
                                                         output:outputOfMinifiedInput
                                                          sigma:kSigma
                                           gaussianEnergyFactor:kGaussianEnergyFactor] process];

    [[[LTBicubicResizeProcessor alloc] initWithInput:outputOfInput
                                              output:minifiedOutputOfInput] process];

    // It shouldn't equal exactly since mathematically the operations are different but should
    // exibit some correspondence.
    expect($([minifiedOutputOfInput image])).to.
        beCloseToMatWithin($([outputOfMinifiedInput image]), 4);
  });
});

SpecEnd
