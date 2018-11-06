// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTQuad.h"
#import "LTTexture+Factory.h"

SpecBegin(LTPatchProcessor)

const std::vector<CGSize> kWorkingSizes{CGSizeMake(64, 64)};

context(@"initialization", ^{
  const CGSize kSize = CGSizeMake(16, 16);

  __block LTTexture *mask;
  __block LTTexture *source;
  __block LTTexture *target;
  __block LTTexture *output;

  beforeEach(^{
    mask = [LTTexture byteRGBATextureWithSize:kSize];
    source = [LTTexture byteRGBATextureWithSize:kSize];
    target = [LTTexture byteRGBATextureWithSize:kSize];
    output = [LTTexture byteRGBATextureWithSize:kSize];
    [output clearColor:LTVector4::zeros()];
  });

  afterEach(^{
    mask = nil;
    source = nil;
    target = nil;
    output = nil;
  });

  it(@"should initialize with proper input", ^{
    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:kWorkingSizes
                                              mask:mask
                                              source:source
                                              target:target
                                              output:output];
    }).toNot.raiseAny();
  });

  it(@"should raise when target size is different than output size", ^{
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMake(kSize.width - 1,
                                                                      kSize.height - 1)];

    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:kWorkingSizes
                                              mask:mask
                                              source:source
                                              target:target
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when working size is not a power of two", ^{
    expect(^{
      std::vector<CGSize> workingSizes{CGSizeMake(32, 32), CGSizeMake(62, 64)};
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:workingSizes
                                              mask:mask
                                              source:source
                                              target:target
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when no working size is given", ^{
    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:{}
                                              mask:mask
                                              source:source
                                              target:target
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when source and target have a different number of channels", ^{
    LTTexture *differentChannelsTexture = [LTTexture byteRedTextureWithSize:kSize];
    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:kWorkingSizes
                                              mask:mask
                                              source:differentChannelsTexture
                                              target:target
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:kWorkingSizes
                                              mask:mask
                                              source:source
                                              target:differentChannelsTexture
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set default values", ^{
    LTPatchProcessor *processor = [[LTPatchProcessor alloc] initWithWorkingSizes:kWorkingSizes
                                                                            mask:mask
                                                                          source:source
                                                                          target:target
                                                                          output:output];
    expect(processor.sourceQuad).to.equal([LTQuad quadFromRect:CGRectFromSize(source.size)]);
    expect(processor.targetQuad).to.equal([LTQuad quadFromRect:CGRectFromSize(target.size)]);
    expect(processor.workingSize).to.equal(kWorkingSizes.front());
    expect(processor.flip).to.equal(NO);
    expect(processor.sourceOpacity).to.equal(1.0);
    expect(processor.smoothingAlpha).to.equal(1.0);
  });
});

context(@"processing", ^{
  const CGSize kSourceSize = CGSizeMake(16, 16);
  const CGSize kTargetSize = CGSizeMake(32, 32);

  __block LTTexture *mask;
  __block LTTexture *source;
  __block LTTexture *target;
  __block LTTexture *output;

  __block LTPatchProcessor *processor;

  beforeEach(^{
    mask = [LTTexture byteRedTextureWithSize:kSourceSize];
    source = [LTTexture byteRGBATextureWithSize:kSourceSize];
    target = [LTTexture byteRGBATextureWithSize:kTargetSize];
    output = [LTTexture byteRGBATextureWithSize:kTargetSize];

    [mask clearColor:LTVector4(1, 1, 1, 1)];
    [source clearColor:LTVector4(0.5, 0, 0, 1)];
    [target clearColor:LTVector4(0, 0, 1, 1)];
    [output clearColor:LTVector4(0, 0, 0, 0)];

    processor = [[LTPatchProcessor alloc] initWithWorkingSizes:kWorkingSizes mask:mask
                                                        source:source target:target output:output];
    processor.targetQuad =
        [LTQuad quadFromRect:CGRectMake(8, 8, kSourceSize.width, kSourceSize.height)];
  });

  afterEach(^{
    processor = nil;
    mask = nil;
    source = nil;
    target = nil;
    output = nil;
  });

  it(@"should clone constant to constant", ^{
    [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetQuad.boundingRect.origin.x,
                 processor.targetQuad.boundingRect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should consider source quads when cloning", ^{
    // Fill (0, 0, 8, 8) with constant data and the rest with random junk.
    cv::Mat4b sourceImage(kSourceSize.height, kSourceSize.width);
    cv::randu(sourceImage, 0, 255);
    sourceImage(cv::Rect(0, 0, 8, 8)) = cv::Vec4b(255, 0, 0, 255);

    [source load:sourceImage];
    source.minFilterInterpolation = LTTextureInterpolationNearest;
    source.magFilterInterpolation = LTTextureInterpolationNearest;

    processor.sourceQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];
    [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetQuad.boundingRect.origin.x,
                 processor.targetQuad.boundingRect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should consider mask when cloning", ^{
    cv::Rect maskROI(0, 0, 8, 8);
    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Scalar::zeros());
      (*mapped)(maskROI).setTo(cv::Scalar::ones() * 255);
    }];
    [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec4b(125, 125, 125, 125));
      (*mapped)(maskROI).setTo(cv::Vec4b(255, 0, 0, 255));
    }];

    mask.minFilterInterpolation = LTTextureInterpolationNearest;
    mask.magFilterInterpolation = LTTextureInterpolationNearest;

    [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetQuad.boundingRect.origin.x,
                 processor.targetQuad.boundingRect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should consider smoothing when cloning", ^{
    cv::Rect maskROI(0, 0, 8, 8);
    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Scalar::zeros());
      (*mapped)(maskROI).setTo(cv::Scalar::ones() * 255);
    }];
    [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec4b(125, 125, 125, 125));
      (*mapped)(maskROI).setTo(cv::Vec4b(255, 0, 0, 255));
    }];

    mask.minFilterInterpolation = LTTextureInterpolationNearest;
    mask.magFilterInterpolation = LTTextureInterpolationNearest;

    processor.smoothingAlpha = 0.5;
    [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetQuad.boundingRect.origin.x,
                 processor.targetQuad.boundingRect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should consider flip when cloning", ^{
    cv::Mat4b sourceImage(kSourceSize.height, kSourceSize.width);
    sourceImage.setTo(cv::Scalar(128, 128, 128, 255));
    cv::Vec4b red(255, 0, 0, 255);
    cv::Vec4b blue(0, 0, 255, 255);
    sourceImage(cv::Rect(0, 0, 4, 8)) = red;
    sourceImage(cv::Rect(4, 0, 4, 8)) = blue;

    [source load:sourceImage];
    source.minFilterInterpolation = LTTextureInterpolationNearest;
    source.magFilterInterpolation = LTTextureInterpolationNearest;

    processor.sourceQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];
    processor.flip = YES;
    [processor process];

    cv::Mat outputMat = [output image];

    CGRect targetRect = processor.targetQuad.boundingRect;
    CGPoint origin = targetRect.origin;

    cv::Vec4b outputLeftValue = outputMat.at<cv::Vec4b>(origin.y, origin.x);
    cv::Vec4b outputRightValue = outputMat.at<cv::Vec4b>(origin.y,
                                                         origin.x + targetRect.size.width  - 1);

    expect(outputRightValue == blue).to.beTruthy();
    expect(outputLeftValue == blue).to.beTruthy();
  });

  context(@"non-constant source", ^{
    __block cv::Mat4b expected;

    beforeEach(^{
      [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        cv::Rect rect(0, 0, kSourceSize.height / 2, kSourceSize.width / 2);
        (*mapped)(rect).setTo(cv::Vec4b(0, 255, 0, 255));
      }];

      expected = LTLoadMat([self class], @"LTPatchProcessorSolution.png");
    });

    it(@"should clone non constant source", ^{
      [processor process];
      expect($([output image])).to.beCloseToMat($(expected));
    });

    it(@"should correctly process with perspectively transformed quads", ^{
      processor.sourceQuad =
          [[LTQuad alloc] initWithCorners:{{{0, 8}, {16, 0}, {16, 16}, {0, 16}}}];
      processor.targetQuad =
          [[LTQuad alloc] initWithCorners:{{{0, 16}, {32, 0}, {32, 32}, {0, 32}}}];
      [processor process];

      cv::Mat expected(LTLoadMat([self class], @"LTPatchProcessorPerspectiveSolution.png"));
      expect($([output image])).to.beCloseToMat($(expected));
    });

    it(@"should consider opacity when cloning", ^{
      processor.sourceOpacity = 0.5;
      [processor process];

      cv::Mat4b expected(LTLoadMat([self class], @"LTPatchProcessorSolution.png"));
      // Since the change is only in the red & green channels, the opacity only affects it.
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(value[0] / 2, value[1] / 2, value[2], value[3]);
      });

      expect($([output image])).to.beCloseToMat($(expected));
    });

    it(@"should redraw target to output on further processings, after it was moved", ^{
      [target cloneTo:output];

      [processor process];
      processor.targetQuad =
          [LTQuad quadFromRect:CGRectMake(0, 0, kSourceSize.width, kSourceSize.height)];
      [processor process];

      // Copy the rect from (8, 8, 8, 8) to (0, 0, 8, 8) as it should be there after the second
      // process. Additionally, make sure the previous location of the rect is filled with the
      // target's original data.
      cv::Mat4b redrawn(expected.size(), cv::Vec4b(0, 0, 255, 255));
      cv::Rect rect(8, 8, kSourceSize.width, kSourceSize.height);
      expected(rect).copyTo(redrawn(cv::Rect(0, 0, kSourceSize.width, kSourceSize.height)));

      expect($([output image])).to.beCloseToMat($(redrawn));
    });
  });

  context(@"source and target with less than 4 channels", ^{
    __block std::vector<cv::Mat1b> solutionRGChannels;

    beforeEach(^{
      std::vector<cv::Mat1b> solutionRGBAChannels;
      cv::split(LTLoadMat([self class], @"LTPatchProcessorSolution.png"), solutionRGBAChannels);
      solutionRGChannels = {solutionRGBAChannels[0], solutionRGBAChannels[1]};
    });

    it(@"should process one channel source and target textures correctly", ^{
      LTTexture *source = [LTTexture byteRedTextureWithSize:kSourceSize];
      [source clearColor:LTVector4(0.5, 0, 0, 1)];
      [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        (*mapped)(cv::Rect(0, 0, kSourceSize.height / 2, kSourceSize.width / 2)).setTo(0);
      }];
      LTTexture *target = [LTTexture byteRedTextureWithSize:kTargetSize];
      [target clearColor:LTVector4(0, 0, 1, 1)];

      processor = [[LTPatchProcessor alloc] initWithWorkingSizes:kWorkingSizes mask:mask
                                                        source:source target:target output:output];
      processor.targetQuad =
          [LTQuad quadFromRect:CGRectMake(8, 8, kSourceSize.width, kSourceSize.height)];
      [processor process];

      std::vector<cv::Mat1b> outputChannels;
      cv::split(output.image, outputChannels);
      expect($(outputChannels[0])).to.beCloseToMat($(solutionRGChannels[0]));
    });

    it(@"should process two channels source and target textures correctly", ^{
      LTTexture *source = [LTTexture textureWithSize:kSourceSize
                                         pixelFormat:$(LTGLPixelFormatRG8Unorm) allocateMemory:YES];
      [source clearColor:LTVector4(0.5, 0, 0, 1)];
      [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        (*mapped)(cv::Rect(0, 0, kSourceSize.height / 2, kSourceSize.width / 2))
            .setTo(cv::Vec2b(0, 255));
      }];
      LTTexture *target = [LTTexture textureWithSize:kTargetSize
                                         pixelFormat:$(LTGLPixelFormatRG8Unorm) allocateMemory:YES];
      [target clearColor:LTVector4(0, 0, 1, 1)];

      processor = [[LTPatchProcessor alloc] initWithWorkingSizes:kWorkingSizes mask:mask
                                                          source:source target:target
                                                          output:output];
      processor.targetQuad =
          [LTQuad quadFromRect:CGRectMake(8, 8, kSourceSize.width, kSourceSize.height)];
      [processor process];

      std::vector<cv::Mat1b> outputChannels;
      cv::split(output.image, outputChannels);
      expect($(outputChannels[0])).beCloseToMat($(solutionRGChannels[0]));
      expect($(outputChannels[1])).beCloseToMat($(solutionRGChannels[1]));
    });
  });
});

SpecEnd
