// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralFrame.h"

#import "LTGLKitExtensions.h"
#import "LTOneShotMultiscaleNoiseProcessor.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(LTProceduralFrame)

__block LTTexture *noise;
__block LTTexture *output;

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

beforeEach(^{
  noise = [LTTexture textureWithImage:LTLoadMatWithName([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:noise];
});

afterEach(^{
  noise =  nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should fail on invalid width parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    expect(^{
      frame.width = -10;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid spread parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    expect(^{
      frame.spread = 1000;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid corner parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    expect(^{
      frame.corner = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid noise amplitude", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    expect(^{
      frame.noiseAmplitude = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid width parameter", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    expect(^{
      frame.width = -10;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on negative color", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    expect(^{
      frame.color = GLKVector3Make(-0.1, 0.9, 0.2);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should return normalized noise channel mixer property", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
    frame.noiseChannelMixer = GLKVector3Make(2.0, 0.0, 0.0);
    expect(frame.noiseChannelMixer == GLKVector3Make(1.0, 0.0, 0.0)).to.beTruthy();
  });
  
  it(@"should not fail on correct input", ^{
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:output];
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
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:frameTexture];
    frame.width = 25;
    frame.spread = 0.0;
    frame.corner = 2;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(1.0, 1.0, 1.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMatWithName([self class], @"RoundWhiteFrame.png")];
    expect($(precomputedFrame.image)).to.beCloseToMat($(frameTexture.image));
  });
  
  it(@"should return straight red frame with abrupt transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 32)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:frameTexture];
    frame.width = 25;
    frame.spread = 0.0;
    frame.corner = 0;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(1.0, 0.0, 0.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMatWithName([self class], @"StraightRedFrame.png")];
    expect($(precomputedFrame.image)).to.beCloseToMat($(frameTexture.image));
  });
  
  it(@"should return straight blue frame with abrupt transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 16)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:frameTexture];
    frame.width = 25;
    frame.spread = 0.0;
    frame.corner = 0;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(0.0, 0.0, 1.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMatWithName([self class], @"StraightBlueFrame.png")];
    expect($(precomputedFrame.image)).to.beCloseToMat($(frameTexture.image));
  });
  
  it(@"should return rounded black frame with thin transition and no noise", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 32)];
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:noise output:frameTexture];
    frame.width = 10.0;
    frame.spread = 10.0;
    frame.corner = 8;
    frame.noiseAmplitude = 0.0;
    frame.color = GLKVector3Make(0.0, 0.0, 0.0);
    [frame process];
    
    LTTexture *precomputedFrame =
        [LTTexture textureWithImage:LTLoadMatWithName([self class], @"RoundishBlackFrame.png")];
    expect($(precomputedFrame.image)).to.beCloseToMat($(frameTexture.image));
  });
  
  it(@"should return straight, black, noisy frame", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(64, 64)];
    LTTexture *tiledNoise =
        [LTTexture textureWithImage:LTLoadMatWithName([self class], @"TiledNoise.png")];
    
    LTProceduralFrame *frame = [[LTProceduralFrame alloc] initWithNoise:tiledNoise
                                                                 output:frameTexture];
    frame.width = 0.0;
    frame.spread = 10.0;
    frame.corner = 0.0;
    frame.noiseAmplitude = 1.0;
    frame.noiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    frame.color = GLKVector3Make(0.0, 0.0, 0.0);
    [frame process];
    
    LTTexture *precomputedFrame = [LTTexture textureWithImage:LTLoadMatWithName([self class],
        @"StraightBlackNoisyFrame.png")];
    expect($(precomputedFrame.image)).to.beCloseToMat($(frameTexture.image));
  });
  
  pending(@"should test tiled noise when implemented");
});

SpecEnd
