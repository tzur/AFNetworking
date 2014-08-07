// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTColorGradient+ForTesting.h"
#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTAnalogFilmProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTAnalogFilmProcessor *processor;

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
    expect(processor.vignetteSpread).to.equal(0);
    expect(processor.vignetteCorner).to.equal(2);
    expect(processor.vignetteNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.vignetteNoiseAmplitude).to.equal(0);
    expect(processor.vignetteOpacity).to.equal(0);
  });
  
  it(@"should return default color gradient settings.", ^{
    expect(processor.colorGradientAlpha).to.equal(0);
    expect(processor.blendMode).to.equal(LTAnalogBlendModeNormal);
    LTTexture *identityGradientTexture = [[LTColorGradient identityGradient]
                                          textureWithSamplingPoints:256];
    expect(LTFuzzyCompareMat(processor.colorGradientTexture.image,
                             identityGradientTexture.image)).to.beTruthy();
  });
  
  it(@"should return default noise of grain and vignetting as constant 0.5", ^{
    cv::Mat4b deafultNoise(1, 1, cv::Vec4b(128, 128, 128, 255));
    expect(LTFuzzyCompareMat(processor.grainTexture.image, deafultNoise)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.vignetteNoise.image, deafultNoise)).to.beTruthy();
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
      processor.vignetteNoise = input;
      processor.vignetteColor = GLKVector3Make(0.0, 0.0, 0.0);
      processor.vignetteSpread = 15.0;
      processor.vignetteCorner = 2.0;
      processor.vignetteNoiseAmplitude = 0.15;
      processor.vignetteNoiseChannelMixer = GLKVector3Make(1.0, 0.2, 0.4);
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct grain input", ^{
    expect(^{
      processor.grainTexture = input;
      processor.grainAmplitude = 0.8;
      processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 0.9);
    }).toNot.raiseAny();
  });
});

context(@"blending modes", ^{
  beforeEach(^{
    cv::Mat4b inputMat(1, 1, cv::Vec4b(64, 64, 64, 255));
    input = [LTTexture textureWithImage:inputMat];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:input output:output];
    processor.colorGradientTexture =
        [[LTColorGradient identityGradient] textureWithSamplingPoints:256];
    processor.colorGradientAlpha = 1.0;
  });
  
  it(@"should process with normal blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    processor.blendMode = LTAnalogBlendModeNormal;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with darken blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    processor.blendMode = LTAnalogBlendModeDarken;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with multiply blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(16, 16, 16, 255));
    processor.blendMode = LTAnalogBlendModeMultiply;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with hard light blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(32, 32, 32, 255));
    processor.blendMode = LTAnalogBlendModeHardLight;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with soft light blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(40, 40, 40, 255));
    processor.blendMode = LTAnalogBlendModeSoftLight;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with lighten blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    processor.blendMode = LTAnalogBlendModeLighten;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with screen blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(112, 112, 112, 255));
    processor.blendMode = LTAnalogBlendModeScreen;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with color burn blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 0, 255));
    processor.blendMode = LTAnalogBlendModeColorBurn;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with overlay blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(33, 33, 33, 255));
    processor.blendMode = LTAnalogBlendModeOverlay;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
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
  
  it(@"should use the most recent input", ^{
    cv::Mat4b input(4, 4, cv::Vec4b(0, 0, 0, 255));
    cv::Mat4b output(4, 4, cv::Vec4b(198, 198, 198, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAnalogFilmProcessor *processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture
                                                                             output:outputTexture];
    processor.brightness = 0.3;
    processor.contrast = 0.2;
    processor.exposure = 0.1;
    processor.offset = 0.1;
    processor.structure = 0.5;
    [processor process];
    
    // Update the input texture and process again, making sure that the processing will be applied
    // on the most recent input.
    [inputTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec4b(128, 128, 128, 255));
    }];
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  // We run this test only on the device. Working assumption is that the smoother (bilateral
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
    processor.vignetteSpread = 45.0;
    processor.vignetteCorner = 6.0;
    processor.vignetteOpacity = 0.25;
    // Grain.
    processor.grainTexture = noise;
    processor.grainAmplitude = 0.25;
    processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 0.5);
    // Color gradient.
    processor.colorGradientTexture =
        [[LTColorGradient magentaYellowGradient] textureWithSamplingPoints:256];
    processor.colorGradientAlpha = 0.275;
    
    [processor process];
    
    // Important: this test heavily depends on the smoother setup and is expected to change after
    // fine-tuning of the smoother.
    cv::Mat image = LTLoadMat([self class], @"IslandAnalogFilm.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 5);
  });
});

SpecGLEnd
