// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTColorGradient.h"
#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTAnalogFilmProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTAnalogFilmProcessor *processor;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTAnalogFilmProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default tone properties correctly", ^{
    expect(processor.brightness).to.equal(0);
    expect(processor.contrast).to.equal(0);
    expect(processor.exposure).to.equal(0);
    expect(processor.structure).to.equal(0);
    expect(processor.saturation).to.equal(0);
  });
  
  it(@"should return default grain properties correctly", ^{
    expect(processor.grainAmplitude).to.equal(0);
    expect(processor.grainChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
  });
  
  it(@"should return default vignetting properties correctly", ^{
    expect(processor.vignetteColor == GLKVector3Make(0, 0, 0)).to.beTruthy();
    expect(processor.vignettingSpread).to.equal(0);
    expect(processor.vignettingCorner).to.equal(2);
    expect(processor.vignettingNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.vignettingNoiseAmplitude).to.equal(1);
    expect(processor.vignettingOpacity).to.equal(0);
  });
  
  it(@"should return default color gradient as identity and its alpha as zero.", ^{
    expect(processor.colorGradientAlpha).to.equal(0);
    LTTexture *identityGradientTexture = [[LTColorGradient identityGradient]
                                          textureWithSamplingPoints:256];
    expect(LTFuzzyCompareMat(processor.colorGradientTexture.image,
                             identityGradientTexture.image)).to.beTruthy();
  });
  
  it(@"should return default noise of grain and vignetting as constant 0.5", ^{
    cv::Mat4b deafultNoise(1, 1, cv::Vec4b(128, 128, 128, 255));
    expect(LTFuzzyCompareMat(processor.grainTexture.image, deafultNoise)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.vignettingNoise.image, deafultNoise)).to.beTruthy();
  });
  
  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.brightness = 0.1;
      processor.contrast = 0.1;
      processor.exposure = 0.1;
      processor.offset = -0.2;
      processor.structure = 0.9;
      processor.saturation = -0.5;
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct vignette input", ^{
    expect(^{
      processor.vignettingNoise = input;
      processor.vignetteColor = GLKVector3Make(0.0, 0.0, 0.0);
      processor.vignettingSpread = 15.0;
      processor.vignettingCorner = 2.0;
      processor.vignettingNoiseAmplitude = 0.15;
      processor.vignettingNoiseChannelMixer = GLKVector3Make(1.0, 0.2, 0.4);
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct grain input", ^{
    expect(^{
      processor.grainTexture = input;
      processor.grainAmplitude = 0.8;
      processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 2.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should process positive brightness and contrast correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(64, 64, 64, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(102, 102, 102, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAnalogFilmProcessor *processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture
                                                                             output:outputTexture];
    processor.brightness = 0.5;
    processor.contrast = 0.15;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process offset correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(0, 0, 0, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(128, 128, 128, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAnalogFilmProcessor *processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture
                                                                             output:outputTexture];
    processor.offset = 0.5;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process tonality correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
    // See lightricks-research/enlight/Adjust/runmeAdjustTonalityTest.m to reproduce this result.
    // Minor differences (~1-3 on 0-255 scale) are expected.
    cv::Mat4b output(1, 1, cv::Vec4b(195, 195, 195, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAnalogFilmProcessor *processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture
                                                                             output:outputTexture];
    processor.brightness = 0.3;
    processor.contrast = 0.2;
    processor.exposure = 0.1;
    processor.offset = 0.1;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process saturation correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(0, 128, 255, 255));
    // Saturation:
    // round(dot((0, 128, 255), (0.299, 0.587, 0.114))) = 104
    // kEpsilon in the shader shifts it to 107, since round(0.01 * 255) = 3.
    cv::Mat4b output(1, 1, cv::Vec4b(107, 107, 107, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAnalogFilmProcessor *processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture
                                                                             output:outputTexture];
    processor.saturation = -1.0;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  // We run this test only on the simulator. Working assumption is that the smoother (bilateral
  // filter) causes up to 27 level differences on some pixels near the strong edges.
  // The overall "feel" of the image should be the same on both the simulator and the devices.
  sit(@"should create correct conversion of luminance, color and details", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Island.jpg")];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.25)];
    
    LTTexture *noise = [LTTexture textureWithImage:LTLoadMat([self class], @"TiledNoise.png")];
    noise.wrap = LTTextureWrapRepeat;
    
    LTAnalogFilmProcessor *processor = [[LTAnalogFilmProcessor alloc] initWithInput:input
                                                                             output:output];
    // Tone.
    processor.exposure = 0.1;
    processor.brightness = 0.1;
    processor.contrast = 0.2;
    processor.offset = 0.1;
    processor.saturation = 0.2;
    processor.structure = -0.1;
    // Vignetting.
    processor.vignetteColor = GLKVector3Make(0.0, 0.0, 0.0);
    processor.vignettingSpread = 45.0;
    processor.vignettingCorner = 6.0;
    processor.vignettingOpacity = 0.25;
    // Grain.
    processor.grainTexture = noise;
    processor.grainAmplitude = 0.5;
    processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 0.5);
    // Color gradient.
    processor.colorGradientTexture =
        [[LTColorGradient magentaYellowGradient] textureWithSamplingPoints:256];
    processor.colorGradientAlpha = 0.55;
    
    [processor process];
    
    // Important: this test heavily depends on the smoother setup and is expected to change after
    // fine-tuning of the smoother.
    cv::Mat image = LTLoadMat([self class], @"IslandAnalogFilm.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
