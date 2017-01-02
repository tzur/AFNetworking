// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchSolverProcessor.h"

#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static LTTexture *LTPatchByteTextureWithSize(CGFloat sourceSize, int channels) {
  LTParameterAssert(channels == 1 || channels == 2 || channels == 4, @"channels (%d) must be in "
                    "{1, 2, 4}", channels);

  cv::Mat sourceMat = cv::Mat::zeros(sourceSize, sourceSize, CV_8UC(channels));
  cv::Rect leftRect = cv::Rect(0, 0, sourceSize / 2, sourceSize);
  cv::Rect rightRect = cv::Rect(sourceSize / 2, 0, sourceSize / 2, sourceSize);

  switch (channels) {
    case 1:
      sourceMat(leftRect).setTo(0);
      sourceMat(rightRect).setTo(255);
      break;
    case 2:
      sourceMat(leftRect).setTo(cv::Vec2b(0, 0));
      sourceMat(rightRect).setTo(cv::Vec2b(255, 255));
      break;
    case 4:
      sourceMat(leftRect).setTo(cv::Vec4b(0, 0, 0, 255));
      sourceMat(rightRect).setTo(cv::Vec4b(255, 255, 255, 255));
    default:
      break;
  }

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

static cv::Mat LTMembraneFromPatchSolverResult(LTTexture *result) {
  cv::Mat membrane;
  LTConvertMat(result.image, &membrane, CV_8UC((int)result.pixelFormat.channels));

  if (membrane.type() == CV_8UC4) {
    cv::Mat4b membrane4b = membrane;
    std::transform(membrane4b.begin(), membrane4b.end(), membrane4b.begin(),
        [](const cv::Vec4b &value) {
          return cv::Vec4b(value[0], value[1], value[2], 255);
        });
  }

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
  
  it(@"should raise with non byte mask texture", ^{
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

  it(@"should raise with non half-float output texture", ^{
    LTTexture *invalidOutput = [LTTexture textureWithSize:CGSizeMake(15, 16)
                                              pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                           allocateMemory:YES];
    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:target
                                                    output:invalidOutput];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when source, target and output have different number of components", ^{
    LTTexture *oneChannelsTexture = [LTTexture byteRedTextureWithSize:source.size];

    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:source target:oneChannelsTexture
                                                    output:output];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      LTPatchSolverProcessor __unused *processor = [[LTPatchSolverProcessor alloc]
                                                    initWithMask:mask
                                                    source:oneChannelsTexture target:target
                                                    output:output];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      LTPatchSolverProcessor __unused *processor =
          [[LTPatchSolverProcessor alloc]
           initWithMask:mask
           source:source target:target
           output:[LTTexture textureWithSize:output.size pixelFormat:$(LTGLPixelFormatR16Float)
                              allocateMemory:YES]];
    }).to.raise(NSInvalidArgumentException);
  });

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

context(@"processing", ^{
  __block LTTexture *mask;
  __block LTTexture *output;

  static const NSUInteger kTextureWidth = 16;
  beforeEach(^{
    mask = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(kTextureWidth)];
    output = [LTTexture textureWithSize:CGSizeMakeUniform(kTextureWidth)
                              pixelFormat:$(LTGLPixelFormatRGBA16Float)
                         allocateMemory:YES];
  });

  afterEach(^{
    mask = nil;
    output = nil;
  });

  it(@"should produce constant membrane on constant inputs", ^{
    LTTexture *source = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(kTextureWidth)];
    LTTexture *target = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(kTextureWidth)];
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
    LTTexture *source = LTPatchByteTextureWithSize(kTextureWidth, 4);
    mask = LTPatchMask(kTextureWidth, 0, 255);
    LTTexture *target = [LTTexture textureWithPropertiesOf:source];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png");
    expect($(LTMembraneFromPatchSolverResult(output))).to.beCloseToMatWithin($(expected), 1);
  });

  it(@"should produce proper membrane for source, target and output with one channel", ^{
    LTTexture *source = LTPatchByteTextureWithSize(kTextureWidth, 1);
    mask = LTPatchMask(kTextureWidth, 0, 255);
    LTTexture *target = [LTTexture textureWithPropertiesOf:source];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];
    output = [LTTexture textureWithSize:CGSizeMakeUniform(kTextureWidth)
                            pixelFormat:$(LTGLPixelFormatR16Float) allocateMemory:YES];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    std::vector<cv::Mat1b> solutionRGBAChannels;
    cv::split(LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png"), solutionRGBAChannels);
    expect($(LTMembraneFromPatchSolverResult(output)))
        .to.beCloseToMatWithin($(solutionRGBAChannels[0]), 1);
  });

  it(@"should produce proper membrane for source, target and output with two channels", ^{
    LTTexture *source = LTPatchByteTextureWithSize(kTextureWidth, 2);
    mask = LTPatchMask(kTextureWidth, 0, 255);
    LTTexture *target = [LTTexture textureWithPropertiesOf:source];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];
    output = [LTTexture textureWithSize:CGSizeMakeUniform(kTextureWidth)
                            pixelFormat:$(LTGLPixelFormatRG16Float) allocateMemory:YES];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask source:source target:target
                                              output:output];
    [processor process];

    std::vector<cv::Mat1b> solutionRGBAChannels;
    cv::split(LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png"), solutionRGBAChannels);
    cv::Mat2b expected;
    cv::merge(std::vector<cv::Mat1b>{solutionRGBAChannels[0], solutionRGBAChannels[1]}, expected);
    expect($(LTMembraneFromPatchSolverResult(output))).to.beCloseToMatWithin($(expected), 1);
  });

  it(@"should produce proper membrane for a custom mask boundary threshold", ^{
    LTTexture *source = LTPatchByteTextureWithSize(kTextureWidth, 4);
    mask = LTPatchMask(kTextureWidth, 100, 200);
    LTTexture *target = [LTTexture textureWithPropertiesOf:source];
    [target clearWithColor:LTVector4(0.5, 0.5, 0.5, 1)];

    LTPatchSolverProcessor *processor =
        [[LTPatchSolverProcessor alloc] initWithMask:mask maskBoundaryThreshold:0.5 source:source
                                              target:target output:output];
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"LTPatchSolverProcessorSolution.png");
    expect($(LTMembraneFromPatchSolverResult(output))).to.beCloseToMatWithin($(expected), 1);
  });

  it(@"should produce proper membrane for source and target with half float percision", ^{
    using half_float::half;

    cv::Mat4hf sourceMat = cv::Mat4hf(kTextureWidth, kTextureWidth);
    sourceMat(cv::Rect(0, 0, kTextureWidth / 2, kTextureWidth))
        .setTo(cv::Vec4hf(half(0), half(0), half(0), half(1)));
    sourceMat(cv::Rect(kTextureWidth / 2, 0, kTextureWidth / 2, kTextureWidth))
        .setTo(cv::Vec4hf(half(1), half(1), half(1), half(1)));

    LTTexture *source = [LTTexture textureWithImage:sourceMat];
    mask = LTPatchMask(kTextureWidth, 0, 255);
    LTTexture *target = [LTTexture textureWithPropertiesOf:source];;
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
