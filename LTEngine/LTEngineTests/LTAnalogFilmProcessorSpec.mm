// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTColorGradient+ForTesting.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTAnalogFilmProcessor)

__block LTTexture *inputTexture;
__block LTTexture *outputTexture;
__block LTAnalogFilmProcessor *processor;

beforeEach(^{
  inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
  processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
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
    expect(processor.structure).to.equal(0);
    expect(processor.saturation).to.equal(0);
    expect(processor.grainAmplitude).to.equal(1);
    expect(processor.grainChannelMixer).to.equal(LTVector3(1, 0, 0));
    expect(processor.vignetteIntensity).to.equal(0);
    expect(processor.vignetteSpread).to.equal(100);
    expect(processor.vignetteCorner).to.equal(2);
    expect(processor.vignetteTransition).to.equal(0);
  });
  
  it(@"should return default color gradient as identity", ^{
    expect(processor.colorGradientIntensity).to.equal(0);
    LTTexture *identityGradientTexture = [[LTColorGradient identityGradient]
                                          textureWithSamplingPoints:256];
    expect(LTFuzzyCompareMat([processor.colorGradient matWithSamplingPoints:256],
                             identityGradientTexture.image)).to.beTruthy();
  });
  
  it(@"should return default grain texture as constant 0.5", ^{
    cv::Mat1b grey(1, 1, 128);
    expect(LTFuzzyCompareMat(processor.grainTexture.image, grey)).to.beTruthy();
  });
  
  it(@"should return default light leak rotation as 0 degrees rotation", ^{
    expect(processor.lightLeakRotation).to.equal(LTLightLeakRotation0);
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
      processor.vignetteIntensity = 0;
      processor.vignetteSpread = 15.0;
      processor.vignetteCorner = 6.0;
      processor.vignetteTransition = 0.75;
    }).toNot.raiseAny();
  });
  
  it(@"should not fail on correct grain input", ^{
    expect(^{
      // Either tileable or of the size of the input.
      LTTexture *grainTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 2)];
      grainTexture.wrap = LTTextureWrapRepeat;
      processor.grainTexture = grainTexture;
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
  
  it(@"should fail on non-square asset texture", ^{
    expect(^{
      processor.assetTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 1)];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on square asset texture with incorrect number of channels", ^{
    expect(^{
      processor.assetTexture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(2)];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on square asset texture of correct size", ^{
    expect(^{
      processor.assetTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  beforeEach(^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0.0, 0.5, 1.0, 1.0)];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
  });
  
  afterEach(^{
    processor = nil;
    inputTexture = nil;
    outputTexture = nil;
  });
  
  it(@"should process brightness correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(2, 225, 255, 255));
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
    processor.brightness = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process contrast correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(0, 135, 255, 255));
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
    cv::Mat4b output(2, 2, cv::Vec4b(1, 255, 255, 255));
    processor.exposure = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process saturation correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(105, 105, 105, 255));
    processor.saturation = -1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process structure correctly", ^{
    cv::Mat4b input(32, 32, cv::Vec4b(0, 0, 0, 255));
    input(0, 0) = cv::Vec4b(192, 192, 192, 255);
    
    cv::Mat4b output(32, 32, cv::Vec4b(32, 32, 32, 255));
    output(0, 0) = cv::Vec4b(255, 255, 255, 255);
    
    inputTexture = [LTTexture textureWithImage:input];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
    processor.structure = 1;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process color gradient correctly", ^{
    cv::Mat4b output(2, 2, cv::Vec4b(16, 65, 255, 255));
    processor.colorGradient = [LTColorGradient redToRedGradient];
    processor.colorGradientIntensity = 1.0;
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process grain correctly", ^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
    
    cv::Mat4b output(2, 2, cv::Vec4b(255, 255, 255, 255));
    [processor.grainTexture clearWithColor:LTVector4(1, 0, 0, 1)];
    processor.grainAmplitude = 1.0;
    processor.grainChannelMixer = LTVector3(1, 0, 0);
    [processor process];
    
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process texture asset correctly", ^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
    [processor.assetTexture clearWithColor:LTVector4One * 0.25];
    processor.lightLeakIntensity = 1.0;
    processor.frameWidth = 1.0;
    [processor process];
    
    cv::Mat4b output(2, 2, cv::Vec4b(112, 112, 112, 255));
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
});

context(@"light leak rotations", ^{
  beforeEach(^{
    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
    [inputTexture clearWithColor:LTVector4(0, 0, 0, 1)];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];

    cv::Mat4b assetImage(2, 2, cv::Vec4b(0, 0, 0, 128));
    assetImage(0, 0) = cv::Vec4b(255, 0, 0, 128);
    LTTexture *assetTexture = [LTTexture textureWithImage:assetImage];

    processor.assetTexture = assetTexture;
    processor.lightLeakIntensity = 1.0;
  });

  afterEach(^{
    processor = nil;
    inputTexture = nil;
    outputTexture = nil;
  });

  it(@"should rotate light leak by 90 degrees correctly", ^{
    processor.lightLeakRotation = LTLightLeakRotation0;
    [processor process];

    cv::Mat4b output(2, 2, cv::Vec4b(0, 0, 0, 255));
    output(0, 0) = cv::Vec4b(255, 0, 0, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });

  it(@"should rotate light leak by 90 degrees correctly", ^{
    processor.lightLeakRotation = LTLightLeakRotation90;
    [processor process];

    cv::Mat4b output(2, 2, cv::Vec4b(0, 0, 0, 255));
    output(0, 1) = cv::Vec4b(255, 0, 0, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });

  it(@"should rotate light leak by 90 degrees correctly", ^{
    processor.lightLeakRotation = LTLightLeakRotation180;
    [processor process];

    cv::Mat4b output(2, 2, cv::Vec4b(0, 0, 0, 255));
    output(1, 1) = cv::Vec4b(255, 0, 0, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });

  it(@"should rotate light leak by 90 degrees correctly", ^{
    processor.lightLeakRotation = LTLightLeakRotation270;
    [processor process];

    cv::Mat4b output(2, 2, cv::Vec4b(0, 0, 0, 255));
    output(1, 0) = cv::Vec4b(255, 0, 0, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
});

context(@"integration tests", ^{
  sit(@"should render natural image", ^{
    inputTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTAnalogFilmProcessor alloc] initWithInput:inputTexture output:outputTexture];
    
    processor.brightness = -0.01;
    processor.contrast = -0.05;
    processor.offset = -0.01;
    processor.exposure = -0.01;
    processor.saturation = 0.1;
    processor.structure = 0.5;
    
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
    
    cv::Mat image = LTLoadMat([self class], @"Lena128AnalogProcessor.png");
    expect($([outputTexture image])).to.beCloseToMatWithin($(image), 4);
  });
});

SpecEnd
