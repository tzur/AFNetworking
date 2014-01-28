// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTFractionalNoise.h"

#import "LTDevice.h"
#import "LTGLTexture.h"
#import "LTTestUtils.h"

SpecBegin(LTFractionalNoise)

__block LTTexture *output;

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

beforeEach(^{
  output = [[LTGLTexture alloc] initByteRGBAWithSize:CGSizeMake(4, 4)];
});

afterEach(^{
  output = nil;
});

context(@"intialization", ^{
  it(@"should fail if texture is nil", ^{
    expect(^{
      __unused LTFractionalNoise *noise = [[LTFractionalNoise alloc] initWithOutput:nil];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should initialize on correct input", ^{
    expect(^{
      __unused LTFractionalNoise *noise = [[LTFractionalNoise alloc] initWithOutput:output];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should fail on incorrect input", ^{
    expect(^{
      LTFractionalNoise *noise = [[LTFractionalNoise alloc] initWithOutput:output];
      noise.amplitude = -0.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should create noise", ^{
    LTFractionalNoise *noise = [[LTFractionalNoise alloc] initWithOutput:output];
    noise.amplitude = 0.5;
    noise.horizontalSeed = 0.0;
    noise.verticalSeed = 0.0;
    noise.velocitySeed = 0.0;
    LTSingleTextureOutput *processed = [noise process];
    
    // Compare current output of the shader with the result that passed human visual inspection.
    // Important: this test may break upon introducing new architectures, since the test is
    // dependent on the round-off errors which may differ on a new architecture.
    // If the test fails, human observer should verify that the noise produced by the round-off
    // errors on the new architecture is visually appealing and then update the test by saving
    // the result as a new gold standard on this architecture.
    cv::Mat image;
    if ([LTDevice currentDevice].deviceType == LTDeviceTypeSimulatorIPhone ||
        [LTDevice currentDevice].deviceType == LTDeviceTypeSimulatorIPad) {
      image = LTLoadMatWithName([self class], @"SimulatorFractionalNoise.png");
    } else {
      image = LTLoadMatWithName([self class], @"iPhone5FractionalNoise.png");
    }
    
    expect(LTFuzzyCompareMat(image, processed.texture.image)).to.beTruthy();
  });
});

SpecEnd
