// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchSolverProcessor.h"

#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static LTTexture *LTPatchByteTextureWithSize(CGFloat sourceSize) {
  cv::Mat4b sourceMat = cv::Mat4b::zeros(sourceSize, sourceSize);
  sourceMat(cv::Rect(0, 0, sourceSize / 2, sourceSize)) = cv::Vec4b(0, 0, 0, 255);
  sourceMat(cv::Rect(sourceSize / 2, 0, sourceSize / 2, sourceSize)) =
      cv::Vec4b(255, 255, 255, 255);
  return [LTTexture textureWithImage:sourceMat];
}

static LTTexture *LTPatchMask(CGFloat maskSize, uchar minValue, uchar maxValue) {
  LTParameterAssert(minValue < maxValue, @"minValue (%uc) must be smaller then maxVlue (%uc)",
                    minValue, maxValue);

  cv::Mat4b maskMat(maskSize, maskSize, cv::Vec4b(maxValue, maxValue, maxValue, 255));
  maskMat(cv::Rect(1, 1, maskSize - 2, maskSize - 2)) =
      cv::Vec4b(minValue, minValue, minValue, 255);
  return [LTTexture textureWithImage:maskMat];
}

static cv::Mat4b LTMembraneFromPatchSolverResult(LTTexture *result) {
  cv::Mat4b membrane;
  LTConvertMat(result.image, &membrane, membrane.type());
  std::transform(membrane.begin(), membrane.end(), membrane.begin(), [](const cv::Vec4b &value) {
    return cv::Vec4b(value[0], value[1], value[2], 255);
  });
  return membrane;
}

SpecBegin(LTPatchSolverProcessor)

context(@"initialization", ^{
  __block LTTexture *mask;
  __block LTTexture *source;
  __block LTTexture *target;
  __block LTTexture *output;

  beforeEach(^{
    mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    source = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    target = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
    output = [LTTexture textureWithSize:CGSizeMake(15, 16) pixelFormat:$(LTGLPixelFormatRGBA16Float)
                         allocateMemory:YES];
  });

  afterEach(^{
    mask = nil;
    source = nil;
    target = nil;
    output = nil;
  });

  it(@"should initialize with a half-float power of two output", ^{
    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:output];
    }).toNot.raiseAny();
  });
  
  it(@"should not initialize with non byte mask texture", ^{
    LTTexture *invalidMask = [LTTexture textureWithSize:CGSizeMake(17, 16)
                                            pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                         allocateMemory:YES];
    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:invalidMask
                                                    source:source target:target
                                                    output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with non half-float output texture", ^{
    LTTexture *invalidOutput = [LTTexture textureWithSize:CGSizeMake(15, 16)
                                              pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                           allocateMemory:YES];
    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:invalidOutput];
    }).to.raise(NSInvalidArgumentException);

    it(@"should raise when the given mask boundary threshold is negative", ^{
      expect(^{
        LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                      initWithMask:mask
                                                      maskBoundaryThreshold:-0.1
                                                      source:source target:target
                                                      output:output];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when the given mask boundary threshold is larger than 1", ^{
      expect(^{
        LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                      initWithMask:mask
                                                      maskBoundaryThreshold:1.1
                                                      source:source target:target
                                                      output:output];
      }).to.raise(NSInvalidArgumentException);
    });
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
                              pixelFormat:$(LTGLPixelFormatRGBA16Float)
                         allocateMemory:YES];
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
  it(@"should produce proper membrane for source and target with byte percision", ^{
    source = LTPatchByteTextureWithSize(kTextureWidth);
    mask = LTPatchMask(kTextureWidth, 0, 255);
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png");
    expect($(LTMembraneFromPatchSolverResult(output))).to.equalMat($(expected));
  });

  it(@"should produce proper membrane for a custom mask boundary threshold", ^{
    source = LTPatchByteTextureWithSize(kTextureWidth);
    mask = LTPatchMask(kTextureWidth, 100, 200);
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask maskBoundaryThreshold:0.5 source:source
                                              target:target output:output];
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png");
    expect($(LTMembraneFromPatchSolverResult(output))).to.equalMat($(expected));
  });

  it(@"should produce proper membrane for source and target with half float percision", ^{
    using half_float::half;

    cv::Mat4hf sourceMat = cv::Mat4hf(kTextureWidth, kTextureWidth);
    sourceMat(cv::Rect(0, 0, kTextureWidth / 2, kTextureWidth))
        .setTo(cv::Vec4hf(half(0), half(0), half(0), half(1)));
    sourceMat(cv::Rect(kTextureWidth / 2, 0, kTextureWidth / 2, kTextureWidth))
        .setTo(cv::Vec4hf(half(1), half(1), half(1), half(1)));

    source = [LTTexture textureWithImage:sourceMat];
    mask = LTPatchMask(kTextureWidth, 0, 255);
    target = [LTTexture textureWithSize:CGSizeMakeUniform(kTextureWidth)
                            pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png");
    expect($(LTMembraneFromPatchSolverResult(output))).to.beCloseToMatWithin($(expected), 1);
  });
});

SpecEnd
