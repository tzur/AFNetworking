// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTClarityProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTClarityProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTClarityProcessor *processor;

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTClarityProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default properties correctly", ^{
    expect(processor.sharpen).to.equal(0);
    expect(processor.fineContrast).to.equal(0);
    expect(processor.mediumContrast).to.equal(0);
    expect(processor.flatten).to.equal(0);
    expect(processor.gain).to.equal(0);
    expect(processor.blackPointShift).to.equal(0);
    expect(processor.saturation).to.equal(0);
  });
});

context(@"synthetic rendering", ^{
  it(@"should return original image on default input", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(64, 128, 192, 255));

    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTClarityProcessor *processor = [[LTClarityProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(input));
  });

  it(@"should not change constant image with sharpen", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(64, 128, 192, 255));

    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTClarityProcessor *processor = [[LTClarityProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];
    processor.sharpen = 1.0;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(input));
  });

  it(@"should process flatten correctly", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(0, 128, 255, 255));
    cv::Mat4b output(16, 16, cv::Vec4b(79, 118, 143 ,255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTClarityProcessor *processor = [[LTClarityProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];
    processor.flatten = 1.0;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });

  it(@"should process gain correctly", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(0, 128, 255, 255));
    cv::Mat4b output(16, 16, cv::Vec4b(0, 223, 255 ,255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTClarityProcessor *processor = [[LTClarityProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];
    processor.gain = 1.0;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });

  it(@"should process black point shift correctly", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(0, 128, 255, 255));
    cv::Mat4b output(16, 16, cv::Vec4b(0, 43, 255 ,255));

    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTClarityProcessor *processor = [[LTClarityProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];
    processor.blackPointShift = 0.5;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process saturation correctly", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(0, 128, 255, 255));
    // round(dot((0, 128, 255), (0.299, 0.587, 0.114))) = 104
    cv::Mat4b output(16, 16, cv::Vec4b(104, 104, 104, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTClarityProcessor *processor = [[LTClarityProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];
    processor.saturation = -1.0;
    [processor process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
});
  
context(@"real world rendering", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    output = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionHalfFloat
                                 format:LTTextureFormatRGBA allocateMemory:YES];
    processor = [[LTClarityProcessor alloc] initWithInput:input output:output];
  });
  
  it(@"should leave image unmodified on default parameters", ^{
    [processor process];
    
    LTTexture *byteOutput = [LTTexture byteRGBATextureWithSize:output.size];
    [output cloneTo:byteOutput];
    
    cv::Mat4b expected(output.size.height, output.size.width);
    cv::resize(LTLoadMat([self class], @"Lena128.png"), expected, expected.size(), 0, 0,
               cv::INTER_LINEAR);
    expect($(byteOutput.image)).to.beCloseToMatWithin($(expected), 1);
  });
    
  sit(@"should apply clarity effect", ^{
    processor.sharpen = 0.5;
    processor.fineContrast = -0.2;
    processor.mediumContrast = 0.1;
    processor.flatten = 0.2;
    processor.gain = 0.1;
    processor.blackPointShift = -0.1;
    processor.saturation = -0.15;
    [processor process];
    
    LTTexture *byteOutput = [LTTexture byteRGBATextureWithSize:output.size];
    [output cloneTo:byteOutput];
    cv::Mat image = LTLoadMat([self class], @"LenaClarity.png");
    expect($(byteOutput.image)).to.beCloseToMatWithin($(image), 1);
  });
});

LTSpecEnd
