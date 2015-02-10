// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDuoProcessor.h"

#import "LTCGExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTDuoProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTDuoProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  processor = [[LTDuoProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default mask properties correctly", ^{
    expect(processor.maskType).to.equal(LTDualMaskTypeRadial);
    expect(processor.center).to.equal(LTVector2Zero);
    expect(processor.diameter).to.equal(0);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
    expect(processor.blueColor).to.equal(LTVector4(0, 0, 1, 1));
    expect(processor.redColor).to.equal(LTVector4(1, 0, 0, 1));
    expect(processor.blendMode).to.equal(LTDuoBlendModeNormal);
    expect(processor.opacity).to.equal(processor.defaultOpacity);
  });
  
  it(@"should fail when passing incorrect red color", ^{
    expect(^{
      processor.blueColor = LTVector4(-0.1, 0, 0, 0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail when passing incorrect blue color", ^{
    expect(^{
      processor.redColor = LTVector4(1.1, 0, 0, 0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct input", ^{
    expect(^{
      processor.blueColor = LTVector4(0.2, 0, 0, 0.9);
      processor.redColor = LTVector4(1, 1, 0, 0);
    }).toNot.raiseAny();
  });
});

context(@"blending modes", ^{
  beforeEach(^{
    cv::Mat4b inputMat(1, 1, cv::Vec4b(64, 64, 64, 255));
    input = [LTTexture textureWithImage:inputMat];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTDuoProcessor alloc] initWithInput:input output:output];
    processor.redColor = LTVector4(0.5, 0.5, 0.5, 1.0);
    processor.blueColor = LTVector4(0.5, 0.5, 0.5, 1.0);
    processor.opacity = 1;
  });
  
  it(@"should process with normal blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(128, 128, 128, 255));
    processor.blendMode = LTDuoBlendModeNormal;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with darken blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    processor.blendMode = LTDuoBlendModeDarken;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with multiply blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(32, 32, 32, 255));
    processor.blendMode = LTDuoBlendModeMultiply;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with hard light blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(65, 65, 65, 255));
    processor.blendMode = LTDuoBlendModeHardLight;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with soft light blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    processor.blendMode = LTDuoBlendModeSoftLight;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with lighten blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(128, 128, 128, 255));
    processor.blendMode = LTDuoBlendModeLighten;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with screen blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(160, 160, 160, 255));
    processor.blendMode = LTDuoBlendModeScreen;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with color burn blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 0, 255));
    processor.blendMode = LTDuoBlendModeColorBurn;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should process with overlay blending mode correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(64, 64, 64, 255));
    processor.blendMode = LTDuoBlendModeOverlay;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
});

context(@"processing", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"SanFrancisco.jpg")];
    CGSize outputSize = input.size * 0.1;
    output = [LTTexture byteRGBATextureWithSize:std::round(outputSize)];
    processor = [[LTDuoProcessor alloc] initWithInput:input output:output];
    // Configure mask.
    processor.maskType = LTDualMaskTypeLinear;
    processor.center = LTVector2(0.5 * outputSize.width, 0.64 * outputSize.height);
    processor.spread = 0.75;
    processor.angle = 0.19;
    processor.opacity = 1.0;
  });
  
  sit(@"should apply blue and red colors", ^{
    processor.blueColor = LTVector4(0.0, 0.2, 0.3, 1.0);
    processor.redColor = LTVector4(0.6, 0.5, 0.2, 1.0);
    processor.blendMode = LTDuoBlendModeOverlay;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"DuoBlueRed.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  sit(@"should apply only blue color", ^{
    processor.blueColor = LTVector4(0.0, 0.2, 0.3, 0.0);
    processor.redColor = LTVector4(0.6, 0.5, 0.2, 0.75);
    processor.spread = -1.0;
    processor.angle = -M_PI_4 * 0.15;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"DuoRed.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  sit(@"should apply only blue color", ^{
    processor.blueColor = LTVector4(0.0, 0.2, 0.3, 0.75);
    processor.redColor = LTVector4(0.6, 0.5, 0.2, 0.0);
    processor.spread = -1.0;
    processor.angle = -M_PI_4 * 0.15;
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"DuoBlue.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});
  
LTSpecEnd
