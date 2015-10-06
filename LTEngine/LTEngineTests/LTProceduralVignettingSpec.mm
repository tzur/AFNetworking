// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralVignetting.h"

#import "LTGLKitExtensions.h"
#import "LTMultiscaleNoiseProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTProceduralVignetting)

__block LTTexture *noise;
__block LTTexture *output;
__block LTProceduralVignetting *processor;

beforeEach(^{
  noise = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:noise];
  processor = [[LTProceduralVignetting alloc] initWithOutput:output];
});

afterEach(^{
  noise =  nil;
  output = nil;
  processor = nil;
});

context(@"properties", ^{
  it(@"should retun default values", ^{
    expect(processor.spread).to.equal(100);
    expect(processor.corner).to.equal(2);
    expect(processor.transition).to.equal(0);
    expect(processor.noiseChannelMixer).to.equal(LTVector3(1, 0, 0));
    expect(processor.noiseAmplitude).to.equal(0);
  });

  it(@"should return default noise texture correctly", ^{
    cv::Mat4b defaultNoise(1, 1, cv::Vec4b(128, 128, 128, 255));

    expect(LTFuzzyCompareMat(processor.noise.image, defaultNoise)).to.beTruthy();
  });
  
  it(@"should fail on invalid spread parameter", ^{
    expect(^{
      processor.spread = 1000;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid corner parameter", ^{
    expect(^{
      processor.corner = 1.5;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid transition", ^{
    expect(^{
      processor.transition = -0.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid noise amplitude", ^{
    expect(^{
      processor.noiseAmplitude = -1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should return normalized noise channel mixer property", ^{
    processor.noiseChannelMixer = LTVector3(-1.0, 0.0, 0.0);
    expect(processor.noiseChannelMixer).to.beCloseToGLKVector(LTVector3(1.0, 0.0, 0.0));
  });
  
  it(@"should not fail on correct input", ^{
    expect(^{
      processor.spread = 25.0;
      processor.corner = 2.0;
      processor.transition = 0.75;
      processor.noiseAmplitude = 2.0;
      processor.noiseChannelMixer = LTVector3(1.0, 1.0, 1.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should return round vignetting pattern", ^{
    LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTProceduralVignetting *processor =
        [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
    processor.corner = 2;
    [processor process];
    
    LTTexture *precomputedVignette =
        [LTTexture textureWithImage:LTLoadMat([self class], @"RoundWideVignetting.png")];
    expect($(precomputedVignette.image)).to.beCloseToMat($(vignetteTexture.image));
  });
  
  it(@"should return rounded rect vignetting pattern", ^{
    LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 32)];
    LTProceduralVignetting *processor =
        [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
    processor.corner = 16;
    [processor process];
    
    LTTexture *precomputedVignette =
        [LTTexture textureWithImage:LTLoadMat([self class], @"StraightWideVignetting.png")];
    expect($(precomputedVignette.image)).to.beCloseToMat($(vignetteTexture.image));
  });
  
  pending(@"should test tiled noise when implemented");
});

LTSpecEnd
