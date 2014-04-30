// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralFrame.h"

#import "LTGLKitExtensions.h"
#import "LTMultiscaleNoiseProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTLTProceduralFrame)

__block LTTexture *noise;
__block LTTexture *output;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

beforeEach(^{
  noise = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:noise];
});

afterEach(^{
  noise =  nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default noise texture correctly", ^{
    cv::Mat4b defaultNoise(1, 1, cv::Vec4b(128, 128, 128, 255));
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(LTFuzzyCompareMat(frame.noise.image, defaultNoise)).to.beTruthy();
  });
  
  it(@"should fail on invalid width parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.width = -10;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid spread parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.spread = 1000;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid corner parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.corner = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid noise amplitude", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.noiseAmplitude = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid width parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.width = -10;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on negative color", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.color = GLKVector3Make(-0.1, 0.9, 0.2);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should return normalized noise channel mixer property", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    frame.noiseChannelMixer = GLKVector3Make(2.0, 0.0, 0.0);
    expect(frame.noiseChannelMixer == GLKVector3Make(1.0, 0.0, 0.0)).to.beTruthy();
  });
  
  it(@"should not fail on correct input", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:output];
    expect(^{
      frame.width = 15.0;
      frame.spread = 25.0;
      frame.corner = 0.0;
      frame.noiseAmplitude = 2.0;
      frame.noiseChannelMixer = GLKVector3Make(1.0, 1.0, 1.0);
      frame.color = GLKVector3Make(1.0, 1.0, 1.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should return round white frame with abrupt transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:frameTexture];
    frame.width = 25;
    frame.spread = 0.0;
    frame.corner = 2;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(1.0, 1.0, 1.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"RoundWhiteFrame.png")];
    expect(LTFuzzyCompareMat(frameTexture.image, precomputedFrame.image)).to.beTruthy();
  });
  
  it(@"should return straight red frame with abrupt transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 32)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:frameTexture];
    frame.width = 25;
    frame.spread = 0.0;
    frame.corner = 0;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(1.0, 0.0, 0.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"StraightRedFrame.png")];
    expect(LTFuzzyCompareMat(frameTexture.image, precomputedFrame.image)).to.beTruthy();
  });
  
  it(@"should return straight blue frame with abrupt transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 16)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:frameTexture];
    frame.width = 25;
    frame.spread = 0.0;
    frame.corner = 0;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(0.0, 0.0, 1.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"StraightBlueFrame.png")];
    expect(LTFuzzyCompareMat(frameTexture.image, precomputedFrame.image)).to.beTruthy();
  });
  
  it(@"should return rounded black frame with thin transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 32)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:frameTexture];
    frame.width = 10.0;
    frame.spread = 10.0;
    frame.corner = 8;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(0.0, 0.0, 0.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"RoundishBlackFrame.png")];
    expect(LTFuzzyCompareMat(frameTexture.image, precomputedFrame.image)).to.beTruthy();
  });
  
  it(@"should return straight, black, noisy frame", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(64, 64)];
    LTTexture *tiledNoise =
        [LTTexture textureWithImage:LTLoadMat([self class], @"TiledNoise.png")];
    
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithOutput:frameTexture];
    frame.width = 0.0;
    frame.spread = 10.0;
    frame.corner = 0.0;
    frame.noise = tiledNoise;
    frame.noiseAmplitude = 1.0;
    frame.noiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    frame.color = GLKVector3Make(0.0, 0.0, 0.0);
    [frame process];
    
    LTTexture *precomputedFrame = [LTTexture textureWithImage:LTLoadMat([self class],
        @"StraightBlackNoisyFrame.png")];
    expect(LTFuzzyCompareMat(frameTexture.image, precomputedFrame.image)).to.beTruthy();
  });
});

SpecEnd
