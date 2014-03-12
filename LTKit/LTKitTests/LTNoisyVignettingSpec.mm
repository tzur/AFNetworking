// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTNoisyVignetting.h"

#import "LTGLKitExtensions.h"
#import "LTOneShotMultiscaleNoiseProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTNoisyVignetting)

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
  it(@"should fail on invalid spread parameter", ^{
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise output:output];
    expect(^{
      vignette.spread = 1000;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid corner parameter", ^{
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise output:output];
    expect(^{
      vignette.corner = 1.5;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid noise amplitude", ^{
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise output:output];
    expect(^{
      vignette.noiseAmplitude = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should return normalized noise channel mixer property", ^{
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise output:output];
    vignette.noiseChannelMixer = GLKVector3Make(2.0, 0.0, 0.0);
    expect(vignette.noiseChannelMixer == GLKVector3Make(1.0, 0.0, 0.0)).to.beTruthy();
  });
  
  it(@"should not fail on correct input", ^{
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise output:output];
    expect(^{
      vignette.spread = 25.0;
      vignette.corner = 2.0;
      vignette.noiseAmplitude = 2.0;
      vignette.noiseChannelMixer = GLKVector3Make(1.0, 1.0, 1.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should return round vignetting pattern", ^{
    LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise
                                                                    output:vignetteTexture];
    vignette.corner = 2;
    vignette.noiseAmplitude = 0.0;
    [vignette process];
    
    LTTexture *precomputedVignette =
        [LTTexture textureWithImage:LTLoadMat([self class], @"RoundWideVignetting.png")];
    expect($(precomputedVignette.image)).to.beCloseToMat($(vignetteTexture.image));
  });
  
  it(@"should return rounded rect vignetting pattern", ^{
    LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 32)];
    LTNoisyVignetting *vignette = [[LTNoisyVignetting alloc] initWithNoise:noise
                                                                    output:vignetteTexture];
    vignette.corner = 16;
    vignette.noiseAmplitude = 0.0;
    [vignette process];
    
    LTTexture *precomputedVignette =
        [LTTexture textureWithImage:LTLoadMat([self class], @"StraightWideVignetting.png")];
    expect($(precomputedVignette.image)).to.beCloseToMat($(vignetteTexture.image));
  });

  pending(@"should test tiled noise when implemented");
});

SpecEnd
