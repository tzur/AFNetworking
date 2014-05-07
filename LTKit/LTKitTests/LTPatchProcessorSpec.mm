// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPatchProcessor.h"

#import "LTCGExtensions.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTPatchProcessor)

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
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc] initWithMask:mask
                                                                             source:source
                                                                             target:target
                                                                             output:output];
    }).toNot.raiseAny();
  });

  it(@"should not initialize if target size is different than output size", ^{
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMake(kSize.width - 1,
                                                                      kSize.height - 1)];

    expect(^{
      LTPatchProcessor __unused *processor = [[LTPatchProcessor alloc] initWithMask:mask
                                                                             source:source
                                                                             target:target
                                                                             output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set default values", ^{
    LTPatchProcessor *processor = [[LTPatchProcessor alloc] initWithMask:mask
                                                                  source:source
                                                                  target:target
                                                                  output:output];
    expect(processor.sourceRect).to.equal([LTRotatedRect
                                           rect:CGRectFromOriginAndSize(CGPointZero, source.size)]);
    expect(processor.targetRect).to.equal([LTRotatedRect
                                           rect:CGRectFromOriginAndSize(CGPointZero, target.size)]);
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
    mask = [LTTexture textureWithSize:kSourceSize precision:LTTexturePrecisionByte
                               format:LTTextureFormatRed allocateMemory:YES];

    source = [LTTexture byteRGBATextureWithSize:kSourceSize];
    target = [LTTexture byteRGBATextureWithSize:kTargetSize];
    output = [LTTexture byteRGBATextureWithSize:kTargetSize];
    [source clearWithColor:GLKVector4Make(0.5, 0, 0, 1)];
    [target clearWithColor:GLKVector4Make(0, 0, 1, 1)];
    [output clearWithColor:GLKVector4Make(0, 0, 0, 0)];

    processor = [[LTPatchProcessor alloc] initWithMask:mask source:source
                                                target:target output:output];
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
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetRect.rect.origin.x,
                 processor.targetRect.rect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([result.texture image])).to.beCloseToMat($(expected));
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
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetRect.rect.origin.x,
                 processor.targetRect.rect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([result.texture image])).to.beCloseToMat($(expected));
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

    [processor maskUpdated];
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b expected = cv::Mat4b::zeros(kTargetSize.height, kTargetSize.width);
    cv::Rect roi(processor.targetRect.rect.origin.x,
                 processor.targetRect.rect.origin.y, kSourceSize.width, kSourceSize.height);
    expected(roi) = cv::Vec4b(0, 0, 255, 255);

    expect($([result.texture image])).to.beCloseToMat($(expected));
  });
});

SpecGLEnd
