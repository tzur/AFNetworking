// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTColorGradient.h"
#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBWProcessor)

__block LTTexture *noise;
__block LTTexture *output;
__block LTBWProcessor *processor;

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
  processor = [[LTBWProcessor alloc] initWithInput:noise output:output];
});

afterEach(^{
  processor =  nil;
  noise =  nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default tone properties correctly", ^{
    expect(processor.brightness).to.equal(0);
    expect(processor.contrast).to.equal(0);
    expect(processor.exposure).to.equal(0);
    expect(processor.structure).to.equal(0);
  });
  
  it(@"should return default grain properties correctly", ^{
    expect(processor.grainAmplitude).to.equal(1);
    expect(processor.grainChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
  });
  
  it(@"should return default vignetting properties correctly", ^{
    expect(processor.vignetteColor == GLKVector3Make(0, 0, 0)).to.beTruthy();
    expect(processor.vignettingSpread).to.equal(0);
    expect(processor.vignettingCorner).to.equal(2);
    expect(processor.vignettingNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.vignettingNoiseAmplitude).to.equal(1);
  });
  
  it(@"should return default outer frame properties correctly", ^{
    expect(processor.outerFrameWidth).to.equal(0);
    expect(processor.outerFrameSpread).to.equal(0);
    expect(processor.outerFrameCorner).to.equal(0);
    expect(processor.outerFrameNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.outerFrameNoiseAmplitude).to.equal(1);
    expect(processor.outerFrameColor == GLKVector3Make(1, 1, 1)).to.beTruthy();
  });
  
  it(@"should return default inner frame properties correctly", ^{
    expect(processor.innerFrameWidth).to.equal(0);
    expect(processor.innerFrameSpread).to.equal(0);
    expect(processor.innerFrameCorner).to.equal(0);
    expect(processor.innerFrameNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.innerFrameNoiseAmplitude).to.equal(1);
    expect(processor.innerFrameColor == GLKVector3Make(1, 1, 1)).to.beTruthy();
  });
  
  it(@"should return default color gradient as identity", ^{
    LTTexture *identityGradientTexture = [[LTColorGradient identityGradient]
                                          textureWithSamplingPoints:256];
    expect(LTFuzzyCompareMat(processor.colorGradientTexture.image,
                             identityGradientTexture.image)).to.beTruthy();
  });
  
  it(@"should return default noise of grain, vignetting and frames as constant 0.5", ^{
    cv::Mat4b deafultNoise(1, 1, cv::Vec4b(128, 128, 128, 255));
    expect(LTFuzzyCompareMat(processor.grainTexture.image, deafultNoise)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.vignettingNoise.image, deafultNoise)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.outerFrameNoise.image, deafultNoise)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.innerFrameNoise.image, deafultNoise)).to.beTruthy();
  });
  
  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.brightness = 0.1;
      processor.contrast = 0.1;
      processor.exposure = 0.1;
      processor.structure = 0.9;
      processor.colorFilter = GLKVector3Make(1.0, 1.0, 0.0);
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct vignette input", ^{
    expect(^{
      processor.vignettingNoise = noise;
      processor.vignetteColor = GLKVector3Make(0.0, 0.0, 0.0);
      processor.vignettingSpread = 15.0;
      processor.vignettingCorner = 6.0;
      processor.vignettingNoiseAmplitude = 0.5;
      processor.vignettingNoiseChannelMixer = GLKVector3Make(1.0, 0.9, 0.2);
    }).toNot.raiseAny();
  });

  it(@"should not fail on correct grain input", ^{
    expect(^{
      processor.grainTexture = noise;
      processor.grainAmplitude = 1.1;
      processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 1.0);
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct outer frame input", ^{
    expect(^{
      processor.outerFrameWidth = 1;
      processor.outerFrameSpread = 0.1;
      processor.outerFrameCorner = 0.0;
      processor.outerFrameNoiseAmplitude = 1.0;
      processor.outerFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
      processor.outerFrameColor = GLKVector3Make(0.0, 0.0, 0.0);
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct inner frame input", ^{
    expect(^{
      processor.innerFrameWidth = 2;
      processor.innerFrameSpread = 0.0;
      processor.innerFrameCorner = 0.0;
      processor.innerFrameNoiseAmplitude = 1.0;
      processor.innerFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
      processor.innerFrameColor = GLKVector3Make(1.0, 0.0, 0.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  sit(@"should return the input black and white image whithout changes on default parameters", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Meal.jpg")];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.25)];
    
    LTTexture *noise = [LTTexture textureWithImage:LTLoadMat([self class], @"TiledNoise.png")];
    noise.wrap = LTTextureWrapRepeat;
    
    LTBWProcessor *processor = [[LTBWProcessor alloc] initWithInput:input output:output];
    // Tone.
    processor.colorFilter = GLKVector3Make(1.0, 0.0, 1.0);
    processor.brightness = 0.1;
    processor.exposure = 0.1;
    processor.structure = 0.3;
    // Vignetting.
    processor.vignettingNoise = noise;
    processor.vignetteColor = GLKVector3Make(0.0, 0.0, 0.0);
    processor.vignettingSpread = 25.0;
    processor.vignettingCorner = 8.0;
    processor.vignettingNoiseAmplitude = 10.0;
    processor.vignettingNoiseChannelMixer = GLKVector3Make(1.0, 0.1, 0.2);
    // Grain.
    processor.grainTexture = noise;
    processor.grainAmplitude = 1.1;
    processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 1.0);
    // Outer frame.
    processor.outerFrameWidth = 1.5;
    processor.outerFrameSpread = 1.5;
    processor.outerFrameCorner = 0.0;
    processor.outerFrameNoiseAmplitude = 1.0;
    processor.outerFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    processor.outerFrameColor = GLKVector3Make(0.0, 0.0, 0.0);
    // Inner frame.
    processor.innerFrameWidth = 2;
    processor.innerFrameSpread = 0.0;
    processor.innerFrameCorner = 0.0;
    processor.innerFrameNoiseAmplitude = 1.0;
    processor.innerFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    processor.innerFrameColor = GLKVector3Make(1.0, 1.0, 1.0);
    // Scale the red channel slightly to create a "neutral-to-cold" gradient.
    CGFloat redScale = 0.95;
    LTColorGradientControlPoint *controlPoint0 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.0 color:GLKVector3Make(0.0, 0.0, 0.0)];
    LTColorGradientControlPoint *controlPoint1 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.25 color:GLKVector3Make(0.25 * redScale, 0.25, 0.25)];
    LTColorGradientControlPoint *controlPoint2 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.5 color:GLKVector3Make(0.5 * redScale, 0.5, 0.5)];
    LTColorGradientControlPoint *controlPoint3 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.75 color:GLKVector3Make(0.75 * redScale, 0.75, 0.75)];
    LTColorGradientControlPoint *controlPoint4 = [[LTColorGradientControlPoint alloc]
        initWithPosition:1.0 color:GLKVector3Make(1.0 * redScale, 1.0, 1.0)];
    NSArray *controlPoints = @[controlPoint0, controlPoint1, controlPoint2, controlPoint3,
                               controlPoint4];
    // Color gradient.
    LTColorGradient *colorGradient = [[LTColorGradient alloc] initWithControlPoints:controlPoints];
    processor.colorGradientTexture = [colorGradient textureWithSamplingPoints:256];;
    
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"MealBWProcessor.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
