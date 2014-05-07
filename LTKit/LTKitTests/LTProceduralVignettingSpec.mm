// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralVignetting.h"

#import "LTGLKitExtensions.h"
#import "LTMultiscaleNoiseProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTProceduralVignetting)

__block LTTexture *noise;
__block LTTexture *output;

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
    LTProceduralVignetting *vignette = [[LTProceduralVignetting alloc] initWithOutput:output];
    expect(LTFuzzyCompareMat(vignette.noise.image, defaultNoise)).to.beTruthy();
  });
  
  it(@"should fail on invalid spread parameter", ^{
    LTProceduralVignetting *vignette = [[LTProceduralVignetting alloc] initWithOutput:output];
    expect(^{
      vignette.spread = 1000;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid corner parameter", ^{
    LTProceduralVignetting *vignette = [[LTProceduralVignetting alloc] initWithOutput:output];
    expect(^{
      vignette.corner = 1.5;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid noise amplitude", ^{
    LTProceduralVignetting *vignette = [[LTProceduralVignetting alloc] initWithOutput:output];
    expect(^{
      vignette.noiseAmplitude = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should return normalized noise channel mixer property", ^{
    LTProceduralVignetting *vignette = [[LTProceduralVignetting alloc] initWithOutput:output];
    vignette.noiseChannelMixer = GLKVector3Make(2.0, 0.0, 0.0);
    expect(vignette.noiseChannelMixer == GLKVector3Make(1.0, 0.0, 0.0)).to.beTruthy();
  });
  
  it(@"should not fail on correct input", ^{
    LTProceduralVignetting *vignette = [[LTProceduralVignetting alloc] initWithOutput:output];
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
    LTProceduralVignetting *vignette =
        [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
    vignette.corner = 2;
    [vignette process];
    
    LTTexture *precomputedVignette =
        [LTTexture textureWithImage:LTLoadMat([self class], @"RoundWideVignetting.png")];
    expect($(precomputedVignette.image)).to.beCloseToMat($(vignetteTexture.image));
  });
  
  it(@"should return rounded rect vignetting pattern", ^{
    LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 32)];
    LTProceduralVignetting *vignette =
        [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
    vignette.corner = 16;
    [vignette process];
    
    LTTexture *precomputedVignette =
        [LTTexture textureWithImage:LTLoadMat([self class], @"StraightWideVignetting.png")];
    expect($(precomputedVignette.image)).to.beCloseToMat($(vignetteTexture.image));
  });
  
  pending(@"should test tiled noise when implemented");
});

SpecGLEnd
