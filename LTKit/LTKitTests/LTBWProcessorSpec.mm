// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTColorGradient.h"
#import "LTColorGradient+ForTesting.h"
#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTBWProcessor)

__block LTTexture *inputTexture;
__block LTTexture *outputTexture;
__block LTBWProcessor *processor;

beforeEach(^{
  inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
  processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
});

afterEach(^{
  processor = nil;
  inputTexture = nil;
  outputTexture = nil;
});

context(@"properties", ^{
  it(@"should return default tone properties correctly", ^{
    expect(processor.brightness).to.equal(0);
    expect(processor.contrast).to.equal(0);
    expect(processor.exposure).to.equal(0);
    expect(processor.offset).to.equal(0);
    expect(processor.structure).to.equal(0);
    expect(processor.grainAmplitude).to.equal(1);
    expect(processor.grainChannelMixer).to.equal(LTVector3(1, 0, 0));
    expect(processor.vignetteIntensity).to.equal(0);
    expect(processor.vignetteSpread).to.equal(100);
    expect(processor.vignetteCorner).to.equal(2);
    expect(processor.vignetteTransition).to.equal(0);
  });
  
  it(@"should return default color gradient as identity", ^{
    expect(processor.colorGradientIntensity).to.equal(1);
    LTTexture *identityGradientTexture = [[LTColorGradient identityGradient]
                                          textureWithSamplingPoints:256];
    expect(LTFuzzyCompareMat([processor.colorGradient matWithSamplingPoints:256],
                             identityGradientTexture.image)).to.beTruthy();
  });
  
  it(@"should return default textures of grain and frames as constant 0.5", ^{
    cv::Mat1b grey(1, 1, 128);
    expect(LTFuzzyCompareMat(processor.frameTexture.image, grey)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.grainTexture.image, grey)).to.beTruthy();
  });
  
  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.brightness = 0.1;
      processor.contrast = 0.1;
      processor.exposure = 0.1;
      processor.structure = 0.9;
      processor.colorFilter = LTVector3(1.0, 1.0, 0.0);
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct vignette input", ^{
    expect(^{
      processor.vignetteIntensity = 0;
      processor.vignetteSpread = 15.0;
      processor.vignetteCorner = 6.0;
      processor.vignetteTransition = 0.75;
    }).toNot.raiseAny();
  });

  it(@"should not fail on correct grain input", ^{
    expect(^{
      // Either tileable or of the size of the input.
      LTTexture *texture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 2)];
      texture.wrap = LTTextureWrapRepeat;
      processor.grainTexture = texture;
      processor.grainTexture = [LTTexture byteRGBATextureWithSize:inputTexture.size];
      processor.grainAmplitude = 1.0;
      processor.grainChannelMixer = LTVector3(0.5, 0.5, 0.0);
    }).toNot.raiseAny();
  });
  
  it(@"should fail on invalid grain texture", ^{
    expect(^{
      LTTexture *texture = [LTTexture byteRedTextureWithSize:CGSizeMake(3, 1)];
      texture.wrap = LTTextureWrapRepeat;
      processor.grainTexture = texture;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct outer frame input", ^{
    expect(^{
      processor.frameTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(16, 16)];
      processor.frameWidth = 0.7;
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on non-square frame texture", ^{
    expect(^{
      processor.frameTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 1)];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  beforeEach(^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
  });
  
  afterEach(^{
    processor = nil;
    inputTexture = nil;
    outputTexture = nil;
  });
  
  it(@"should process brightness correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(217, 217, 217, 255));
    processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
    processor.brightness = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process contrast correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(104, 104, 104, 255));
    processor.contrast = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process offset correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(255, 255, 255, 255));
    processor.offset = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process exposure correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(233, 233, 233, 255));
    processor.exposure = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process structure correctly", ^{
    // Histogram equalization should map 0.75 to 1.0.
    cv::Mat4b input(2, 2, cv::Vec4b(0, 0, 0, 255));
    input(0, 0) = cv::Vec4b(192, 192, 192, 255);
    
    cv::Mat4b output(2, 2, cv::Vec4b(0, 0, 0, 255));
    output(0, 0) = cv::Vec4b(255, 255, 255, 255);
    
    inputTexture = [LTTexture textureWithImage:input];
    processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
    processor.structure = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process color filter correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(64, 64, 64, 255));
    processor.colorFilter = LTVector3(1, 0, 0);
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process color gradient correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(255, 0, 0, 255));
    processor.colorGradient = [LTColorGradient redToRedGradient];
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process grain correctly", ^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
    processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
    
    cv::Mat4b output(2, 2, cv::Vec4b(255, 255, 255, 255));
    [processor.grainTexture clearWithColor:LTVector4(1, 0, 0, 1)];
    processor.grainAmplitude = 1.0;
    processor.grainChannelMixer = LTVector3(1, 0, 0);
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process frame correctly", ^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
    processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
    
    cv::Mat4b output(2, 2, cv::Vec4b(0, 0, 0, 255));
    // Only the first channel should be used.
    [processor.frameTexture clearWithColor:LTVector4(0, 1, 1, 1)];
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
});

context(@"integration tests", ^{
  sit(@"should render natural image", ^{
    inputTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTBWProcessor alloc] initWithInput:inputTexture output:outputTexture];
    
    processor.brightness = -0.01;
    processor.contrast = -0.05;
    processor.offset = -0.01;
    processor.exposure = -0.01;
    processor.structure = 0.5;
    
    processor.colorFilter = LTVector3(1.1, -0.125, -0.125);
    processor.colorGradient = [LTColorGradient magentaYellowGradient];
    processor.colorGradientFade = 0.1;
    processor.colorGradientIntensity = 0.2;
    
    LTTexture *grain = [LTTexture textureWithImage:LTLoadMat([self class], @"TonalGrain.png")];
    grain.wrap = LTTextureWrapRepeat;
    processor.grainTexture = grain;
    processor.grainChannelMixer = LTVector3(0.0, 0.5, 0.5);
    processor.grainAmplitude = 0.3;
    
    processor.vignetteIntensity = 0.75;
    processor.vignetteSpread = 25;
    processor.vignetteCorner = 2;
    processor.vignetteTransition = 0.1;

    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"Lena128BWProcessor.png");
    expect($([outputTexture image])).to.beCloseToMatWithin($(image), 4);
  });
});

LTSpecEnd
