// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTMultiscaleNoiseProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTMultiscaleNoiseProcessor)

__block LTTexture *output;

beforeEach(^{
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(128, 64)];
});

afterEach(^{
  output = nil;
});

context(@"intialization", ^{
  it(@"should fail if texture is nil", ^{
    expect(^{
      __unused LTMultiscaleNoiseProcessor *noise = [[LTMultiscaleNoiseProcessor alloc]
                                                    initWithOutput:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  sit(@"should create noise", ^{
    LTMultiscaleNoiseProcessor *noise = [[LTMultiscaleNoiseProcessor alloc]
                                         initWithOutput:output];
    noise.seed = 0.25;
    noise.density = 2.0;
    [noise process];
    // Compare current output of the shader with the result that passed human visual inspection.
    // Important: this test may break upon introducing new architectures, since the test is
    // dependent on the round-off errors which may differ on a new architecture.
    // If the test fails, human observer should verify that the noise produced by the round-off
    // errors on the new architecture is visually appealing and then update the test by saving
    // the result as a new gold standard on this architecture.
    cv::Mat image = LTLoadMat([self class], @"SimulatorMultiscaleNoise.png");

    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});

SpecEnd
