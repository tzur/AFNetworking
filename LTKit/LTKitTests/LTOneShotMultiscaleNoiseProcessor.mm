// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotMultiscaleNoiseProcessor.h"

#import "LTGLTexture.h"
#import "LTTestUtils.h"

SpecBegin(LTOneShotMultiscaleNoiseProcessor)

__block LTTexture *output;

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

beforeEach(^{
  output = [[LTGLTexture alloc] initByteRGBAWithSize:CGSizeMake(128, 64)];
});

afterEach(^{
  output = nil;
});

context(@"intialization", ^{
  it(@"should fail if texture is nil", ^{
    expect(^{
      __unused LTOneShotMultiscaleNoiseProcessor *noise = [[LTOneShotMultiscaleNoiseProcessor alloc]
                                                           initWithOutput:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  it(@"should create noise", ^{
    LTOneShotMultiscaleNoiseProcessor *noise = [[LTOneShotMultiscaleNoiseProcessor alloc]
                                                initWithOutput:output];
    noise[@"seed"] = @(0.25);
    noise[@"density"] = @(2.0);
    LTSingleTextureOutput *processed = [noise process];
    
    // Compare current output of the shader with the result that passed human visual inspection.
    // Important: this test may break upon introducing new architectures, since the test is
    // dependent on the round-off errors which may differ on a new architecture.
    // If the test fails, human observer should verify that the noise produced by the round-off
    // errors on the new architecture is visually appealing and then update the test by saving
    // the result as a new gold standard on this architecture.
    cv::Mat image = LTLoadDeviceDependentMat([self class], @"SimulatorMultiscaleNoise.png",
                                             @"iPhone5MultiscaleNoise.png");
    expect(LTFuzzyCompareMat(image, processed.texture.image)).to.beTruthy();
  });
});

SpecEnd
