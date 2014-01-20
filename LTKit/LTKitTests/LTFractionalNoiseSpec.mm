// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTFractionalNoise.h"

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
  output = [[LTGLTexture alloc] initWithSize:CGSizeMake(32, 32)
                                   precision:LTTexturePrecisionByte
                                    channels:LTTextureChannelsRGBA
                              allocateMemory:YES];
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
  
  it(@"should fail on incorrect input", ^{
    expect(^{
      LTFractionalNoise *noise = [[LTFractionalNoise alloc] initWithOutput:output];
      noise.frequency = 2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  fit(@"should create noise", ^{
    LTFractionalNoise *noise = [[LTFractionalNoise alloc] initWithOutput:output];
    noise.amplitude = 0.25;
    noise.frequency = 1.0;
    LTSingleTextureOutput *processed = [noise process];
    LTTexture *tex = processed.texture;
    tex;
    noise.amplitude = 0.0;
    expect(LTFuzzyCompareMat(tex.image, tex.image)).to.beTruthy();
  });
});

SpecEnd
