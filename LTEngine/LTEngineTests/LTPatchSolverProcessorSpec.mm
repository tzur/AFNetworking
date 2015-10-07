// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchSolverProcessor.h"

#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTPatchSolverProcessor)

context(@"initialization", ^{
  it(@"should initialize with a half-float power of two output", ^{
    LTTexture *mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *source = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *target = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *output = [LTTexture textureWithSize:CGSizeMake(15, 16)
                                         precision:LTTexturePrecisionHalfFloat
                                            format:LTTextureFormatRGBA allocateMemory:YES];

    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:output];
    }).toNot.raiseAny();
  });
  
  it(@"should not initialize with non half-float texture", ^{
    LTTexture *mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *source = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *target = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    LTTexture *output = [LTTexture textureWithSize:CGSizeMake(15, 16)
                                         precision:LTTexturePrecisionByte
                                            format:LTTextureFormatRGBA allocateMemory:YES];

    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  __block LTTexture *source;
  __block LTTexture *target;
  __block LTTexture *mask;
  __block LTTexture *output;

  static const NSUInteger kTextureWidth = 16;
  beforeEach(^{
    source = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(kTextureWidth)];
    target = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(kTextureWidth)];
    mask = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(kTextureWidth)];
    output = [LTTexture textureWithSize:CGSizeMakeUniform(kTextureWidth)
                              precision:LTTexturePrecisionHalfFloat
                                 format:LTTextureFormatRGBA allocateMemory:YES];

  });

  afterEach(^{
    source = nil;
    target = nil;
    mask = nil;
    output = nil;
  });

  it(@"should produce constant membrane on constant inputs", ^{
    [source clearWithColor:LTVector4(0.75, 0.75, 0.75, 1)];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];
    [mask clearWithColor:LTVector4(1, 1, 1, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    expect($([output image])).to.beCloseToScalarWithin($(cv::Scalar(-0.25, -0.25, -0.25, 0)), 1e-2);
  });

  // Creates input texture which is half white and half black, gray target texture a mask with white
  // at its boundaries. Verify that the patch solver creates the expected smoothing membrane. Verify
  // that the black and white pixels of the images do not affect the opposite side in the membrane
  // texture.
  it(@"should produce proper membrane for input", ^{
    cv::Mat4b sourceMat = cv::Mat4b::zeros(kTextureWidth, kTextureWidth);
    sourceMat(cv::Rect(0, 0, kTextureWidth / 2, kTextureWidth)) = cv::Vec4b(0, 0, 0, 255);
    sourceMat(cv::Rect(kTextureWidth / 2, 0, kTextureWidth / 2, kTextureWidth)) =
        cv::Vec4b(255, 255, 255, 255);
    source = [LTTexture textureWithImage:sourceMat];
    cv::Mat4b maskMat(kTextureWidth, kTextureWidth, cv::Vec4b(255, 255, 255, 255));
    maskMat(cv::Rect(1, 1, kTextureWidth - 2, kTextureWidth - 2)) = cv::Vec4b(0, 0, 0, 255);
    mask = [LTTexture textureWithImage:maskMat];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    cv::Mat4b membrane;
    LTConvertMat(output.image, &membrane, membrane.type());
    std::transform(membrane.begin(), membrane.end(), membrane.begin(), [](const cv::Vec4b &value) {
      return cv::Vec4b(value[0], value[1], value[2], 255);
    });

    cv::Mat4b expected = LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png");
    expect($(membrane)).to.equalMat($(expected));
  });

});

SpecEnd
