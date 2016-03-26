// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTCircularPatchProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTCircularPatchProcessor)

__block LTCircularPatchProcessor *processor;
__block LTTexture *inputTexture;
__block LTTexture *outputTexture;
__block CGSize textureSize;

beforeEach(^{
  inputTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
  inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
  inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
  textureSize = inputTexture.size;

  outputTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
  outputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
  outputTexture.minFilterInterpolation = LTTextureInterpolationNearest;

  processor = [[LTCircularPatchProcessor alloc] initWithInput:inputTexture output:outputTexture];
});

afterEach(^{
  processor = nil;
  inputTexture = nil;
  outputTexture = nil;
});

it(@"should raise exception if input texture size is different than output texture size.", ^{
  expect(^{
    outputTexture = [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Vec4b(0, 0, 0, 1))];
    processor = [[LTCircularPatchProcessor alloc] initWithInput:inputTexture output:outputTexture];
  }).to.raise(NSInvalidArgumentException);
});

context(@"process patch", ^{
  it(@"should patch as the default circular patch mode", ^{
    expect(processor.circularPatchMode).to.equal(LTCircularPatchModePatch);
  });

  it(@"should patch with default values", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.75);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchDefault.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should not effect image when source equals target", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 5;
    processor.featheringAlpha = 0.5;
    [processor process];

    expect($(outputTexture.image)).to.equalMat($(inputTexture.image));
  });

  it(@"should patch with rotation", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    processor.rotation = M_PI_2;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchRotation.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should patch with alpha", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.6, textureSize.height * 0.6);
    processor.targetCenter = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    processor.radius = textureSize.width / 4;
    processor.alpha = 0.5;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchAlpha.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should patch with feathering alpha", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.targetCenter = CGPointMake(textureSize.width * 0.35, textureSize.height * 0.55);
    processor.radius = textureSize.width / 5;
    processor.featheringAlpha = 0.5;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchFeathering.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should patch with flip", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.6, textureSize.height * 0.6);
    processor.targetCenter = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    processor.radius = textureSize.width / 4;
    processor.flip = YES;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchFlipped.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });
});

context(@"process heal", ^{
  beforeEach(^{
    processor.circularPatchMode = LTCircularPatchModeHeal;
  });

  it(@"should heal with default values", ^{
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularHealDefault.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should ignore source center", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.75, textureSize.height * 0.35);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularHealDefault.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should not have effect when rotation is set", ^{
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    processor.rotation = M_PI_2;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularHealDefault.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should heal with alpha", ^{
    processor.targetCenter = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    processor.radius = textureSize.width / 6;
    processor.alpha = 0.9;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularHealAlpha.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should heal with feathering alpha", ^{
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 5;
    processor.featheringAlpha = 0.3;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularHealFeathering.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });
});

context(@"process clone", ^{
  beforeEach(^{
    processor.circularPatchMode = LTCircularPatchModeClone;
  });

  it(@"should clone with default values", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.25);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularCloneDefault.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should clone with rotation", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.65, textureSize.height * 0.5);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    processor.rotation = M_PI;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularCloneRotation.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should clone with alpha", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.7, textureSize.height * 0.2);
    processor.targetCenter = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    processor.radius = textureSize.width / 7;
    processor.alpha = 0.3;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularCloneAlpha.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should clone with feathering alpha", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.45, textureSize.height * 0.55);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 5;
    processor.featheringAlpha = 0.8;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularCloneFeathering.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });
});

context(@"process patch outside of image", ^{
  it(@"should mirror source", ^{
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.sourceCenter = CGPointMake(0, textureSize.height * 0.5);
    processor.radius = textureSize.width / 4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchMirror.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should not effect image when source equals target", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 5;
    [processor process];

    expect($(outputTexture.image)).to.beCloseToMatWithin($(inputTexture.image), 2);
  });

  it(@"should double mirror source", ^{
    processor.sourceCenter = CGPointMake(textureSize.width, textureSize.height);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    processor.radius = textureSize.width / 5;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchDoubleMirror.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });

  it(@"should draw only visible target", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, 0);
    processor.radius = textureSize.width / 5;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"CircularPatchVisibleTarget.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 2);
  });
});

context(@"synthetic input texture", ^{
  const cv::Vec4b kWhite(255, 255, 255, 255);
  const cv::Vec4b kBlack(0, 0, 0, 255);

  beforeEach(^{
    textureSize = CGSizeMake(50, 30);
    cv::Mat4b inputMat(textureSize.height, textureSize.width, kBlack);
    inputMat(cv::Rect(0, 0, textureSize.width, textureSize.height)).setTo(kWhite);
    inputMat(cv::Rect(0, 0, textureSize.width / 2, textureSize.height / 2)).setTo(kBlack);
    inputMat(cv::Rect(textureSize.width / 2, textureSize.height / 2, textureSize.width / 2,
                      textureSize.height / 2)).setTo(kBlack);
    inputTexture = [LTTexture textureWithImage:inputMat];
    outputTexture = [LTTexture textureWithImage:inputMat];

    processor = [[LTCircularPatchProcessor alloc] initWithInput:inputTexture output:outputTexture];
  });

  afterEach(^{
    processor = nil;
    inputTexture = nil;
    outputTexture = nil;
  });

  it(@"should rotate 180 degrees without artifacts", ^{
    processor.sourceCenter = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.5);
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.25);
    processor.radius = textureSize.height / 4;
    processor.rotation = -M_PI_2;
    [processor process];

    expect($(outputTexture.image)).to.beCloseToMatWithin($(inputTexture.image), 2);
  });

  it(@"should return zero source-target boundary error", ^{
    CGPoint bestSourceCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.25);
    CGPoints sourceCenters;
    sourceCenters.push_back(CGPointMake(textureSize.width * 0.46, textureSize.height * 0.25));
    sourceCenters.push_back(CGPointMake(textureSize.width * 0.54, textureSize.height * 0.25));
    sourceCenters.push_back(bestSourceCenter);
    sourceCenters.push_back(CGPointMake(textureSize.width * 0.5, textureSize.height * 0.21));
    sourceCenters.push_back(CGPointMake(textureSize.width * 0.5, textureSize.height * 0.29));
    processor.targetCenter = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.25);
    processor.radius = textureSize.height / 4;
    [processor setBestSourceCenterForCenters:sourceCenters];
    expect(processor.sourceCenter).to.equal(bestSourceCenter);
  });
});

SpecEnd
