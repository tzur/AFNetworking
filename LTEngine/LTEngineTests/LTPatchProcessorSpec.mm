// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

SpecBegin(LTPatchProcessor)

const CGSizes kWorkingSizes{CGSizeMake(64, 64)};

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

  it(@"should not initialize if target size is different than output size", ^{
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

  it(@"should not initialize if working size is not a power of two", ^{
    expect(^{
      CGSizes workingSizes{CGSizeMake(32, 32), CGSizeMake(62, 64)};
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:workingSizes
                                              mask:mask
                                              source:source
                                              target:target
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize if no working size is given", ^{
    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc]
                                              initWithWorkingSizes:{}
                                              mask:mask
                                              source:source
                                              target:target
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set default values", ^{
    LTPatchProcessor *processor = [[LTPatchProcessor alloc] initWithWorkingSizes:kWorkingSizes
                                                                            mask:mask
                                                                          source:source
                                                                          target:target
                                                                          output:output];
    expect(processor.sourceRect).to.equal([LTRotatedRect
                                           rect:CGRectFromOriginAndSize(CGPointZero, source.size)]);
    expect(processor.targetRect).to.equal([LTRotatedRect
                                           rect:CGRectFromOriginAndSize(CGPointZero, target.size)]);
    expect(processor.workingSize).to.equal(kWorkingSizes.front());
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

    [mask clearWithColor:LTVector4(1, 1, 1, 1)];
    [source clearWithColor:LTVector4(0.5, 0, 0, 1)];
    [target clearWithColor:LTVector4(0, 0, 1, 1)];
    [output clearWithColor:LTVector4(0, 0, 0, 0)];

    processor = [[LTPatchProcessor alloc] initWithWorkingSizes:kWorkingSizes mask:mask
                                                        source:source target:target output:output];
    processor.targetRect = [LTRotatedRect rect:CGRectMake(8, 8,
                                                          kSourceSize.width, kSourceSize.height)];
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
    cv::Rect roi(processor.targetRect.rect.origin.x,
                 processor.targetRect.rect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should consider source rect when cloning", ^{
    // Fill (0, 0, 8, 8) with constant data and the rest with random junk.
    cv::Mat4b sourceImage(kSourceSize.height, kSourceSize.width);
    cv::randu(sourceImage, 0, 255);
    sourceImage(cv::Rect(0, 0, 8, 8)) = cv::Vec4b(255, 0, 0, 255);

    [source load:sourceImage];
    source.minFilterInterpolation = LTTextureInterpolationNearest;
    source.magFilterInterpolation = LTTextureInterpolationNearest;

    processor.sourceRect = [LTRotatedRect rect:CGRectMake(0, 0, 8, 8)];
    [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetRect.rect.origin.x,
                 processor.targetRect.rect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should consider mask when cloning", ^{
    // Put constant values only where mask == 1, and random junk anywhere else.
    cv::Rect maskROI(0, 0, 8, 8);
    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Scalar::zeros());
      (*mapped)(maskROI).setTo(cv::Scalar::ones() * 255);
    }];
    [source mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      cv::randu(*mapped, cv::Vec4b::zeros(), cv::Vec4b::ones() * 255);
      (*mapped)(maskROI).setTo(cv::Vec4b(255, 0, 0, 255));
    }];

    mask.minFilterInterpolation = LTTextureInterpolationNearest;
    mask.magFilterInterpolation = LTTextureInterpolationNearest;

    [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetRect.rect.origin.x,
                 processor.targetRect.rect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([output image])).to.beCloseToMat($(expected));
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
      processor.targetRect = [LTRotatedRect
                              rect:CGRectMake(0, 0, kSourceSize.width, kSourceSize.height)];
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
});

SpecEnd
