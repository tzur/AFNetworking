// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageBorderProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTImageBorderProcessor)

__block LTTexture *inputTexture;
__block LTTexture *outputTexture;
__block LTImageBorderProcessor *processor;

beforeEach(^{
  inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
  outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
  processor = [[LTImageBorderProcessor alloc] initWithInput:inputTexture output:outputTexture];
});

afterEach(^{
  processor = nil;
  inputTexture = nil;
  outputTexture = nil;
});

context(@"properties", ^{
  it(@"should return default properties correctly", ^{
    expect(processor.width).to.equal(0);
    expect(processor.spread).to.equal(0);
    expect(processor.color).to.equal(LTVector3(1, 1, 1));
    expect(processor.opacity).to.equal(1);
    expect(processor.frontSymmetrization).to.equal(LTSymmetrizationTypeOriginal);
    expect(processor.backSymmetrization).to.equal(LTSymmetrizationTypeOriginal);
    expect(processor.edge0).to.equal(0);
    expect(processor.edge1).to.equal(0.25);
    expect(processor.frontFlipHorizontal).to.beFalsy();
    expect(processor.frontFlipVertical).to.beFalsy();
    expect(processor.backFlipHorizontal).to.beFalsy();
    expect(processor.backFlipVertical).to.beFalsy();
  });

  it(@"should return default textures as constant 0.5", ^{
    cv::Mat1b grey(1, 1, 128);
    expect(LTFuzzyCompareMat(processor.frontTexture.image, grey)).to.beTruthy();
    expect(LTFuzzyCompareMat(processor.backTexture.image, grey)).to.beTruthy();
  });

  it(@"should not fail on correct input", ^{
    expect(^{
      processor.width = 0.1;
      processor.spread = 0.1;
      processor.color = LTVector3::zeros();
      processor.opacity = 0.2;
      processor.frontSymmetrization = LTSymmetrizationTypeTop;
      processor.backSymmetrization = LTSymmetrizationTypeBottom;
      processor.edge0 = 0.1;
      processor.edge1 = 0.2;
      processor.frontFlipHorizontal = YES;
      processor.frontFlipVertical = NO;
      processor.backFlipHorizontal = YES;
      processor.backFlipVertical = NO;
    }).toNot.raiseAny();
  });

  it(@"should fail on non-square front texture", ^{
    expect(^{
      processor.frontTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 1)];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on non-square back texture", ^{
    expect(^{
      processor.backTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 1)];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not fail on square front texture", ^{
    expect(^{
      processor.frontTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 2)];
    }).toNot.raiseAny();
  });

  it(@"should not fail on square back texture", ^{
    expect(^{
      processor.backTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 2)];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  __block LTTexture *frameTexture;
  beforeEach(^{
    cv::Mat4b greyPatch(2, 2, cv::Vec4b(128, 128, 128, 255));
    inputTexture = [LTTexture textureWithImage:greyPatch];
    outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    processor = [[LTImageBorderProcessor alloc] initWithInput:inputTexture output:outputTexture];
    processor.edge0 = 0.49;
    processor.edge1 = 0.5;
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 0) = cv::Vec4b(255, 255, 255, 255);
    frameTexture = [LTTexture textureWithImage:frame];
  });

  afterEach(^{
    frameTexture = nil;
  });

  it(@"should flip front texture horizontally", ^{
    processor.frontTexture = frameTexture;
    processor.frontFlipHorizontal = YES;
    [processor process];
    
    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(0, 0, 0, 255);
    expected(0, 1) = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should flip front texture vertically", ^{
    processor.frontTexture = frameTexture;
    processor.frontFlipVertical = YES;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(0, 0, 0, 255);
    expected(1, 0) = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should flip front texture on both axis", ^{
    processor.frontTexture = frameTexture;
    processor.frontFlipHorizontal = YES;
    processor.frontFlipVertical = YES;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(0, 0, 0, 255);
    expected(1, 1) = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should flip back texture horizontally", ^{
    processor.backTexture = frameTexture;
    processor.backFlipHorizontal = YES;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(0, 0, 0, 255);
    expected(0, 1) = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should flip back texture vertically", ^{
    processor.backTexture = frameTexture;
    processor.backFlipVertical = YES;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(0, 0, 0, 255);
    expected(1, 0) = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should flip back texture on both axis", ^{
    processor.backTexture = frameTexture;
    processor.backFlipHorizontal = YES;
    processor.backFlipVertical = YES;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(0, 0, 0, 255);
    expected(1, 1) = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should use original front frame texure for LTSymmetrizationTypeOriginal", ^{
    processor.frontTexture = frameTexture;
    processor.frontSymmetrization = LTSymmetrizationTypeOriginal;
    [processor process];

    expect($(outputTexture.image)).to.beCloseToMatWithin($(frameTexture.image), 4);
  });

  it(@"should symmetrize front texture using top left", ^{
    processor.frontTexture = frameTexture;
    processor.frontSymmetrization = LTSymmetrizationTypeTopLeft;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using top right", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeTopRight;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using bottom left", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(1, 0) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeBottomLeft;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using bottom right", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(1, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeBottomRight;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using top", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 0) = cv::Vec4b(255, 255, 255, 255);
    frame(0, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeTop;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using bottom", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(1, 0) = cv::Vec4b(255, 255, 255, 255);
    frame(1, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeBottom;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using left", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 0) = cv::Vec4b(255, 255, 255, 255);
    frame(1, 0) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeLeft;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize front texture using right", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 1) = cv::Vec4b(255, 255, 255, 255);
    frame(1, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.frontTexture = [LTTexture textureWithImage:frame];
    processor.frontSymmetrization = LTSymmetrizationTypeRight;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should use original back frame texure for LTSymmetrizationTypeOriginal", ^{
    processor.backTexture = frameTexture;
    processor.backSymmetrization = LTSymmetrizationTypeOriginal;
    [processor process];

    expect($(outputTexture.image)).to.beCloseToMatWithin($(frameTexture.image), 4);
  });

  it(@"should symmetrize back texture using top left", ^{
    processor.backTexture = frameTexture;
    processor.backSymmetrization = LTSymmetrizationTypeTopLeft;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using top right", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeTopRight;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using bottom left", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(1, 0) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeBottomLeft;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using bottom right", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(1, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeBottomRight;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using top", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 0) = cv::Vec4b(255, 255, 255, 255);
    frame(0, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeTop;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using bottom", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(1, 0) = cv::Vec4b(255, 255, 255, 255);
    frame(1, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeBottom;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using left", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 0) = cv::Vec4b(255, 255, 255, 255);
    frame(1, 0) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeLeft;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });

  it(@"should symmetrize back texture using right", ^{
    cv::Mat4b frame(2, 2);
    frame = cv::Vec4b(0, 0, 0, 255);
    frame(0, 1) = cv::Vec4b(255, 255, 255, 255);
    frame(1, 1) = cv::Vec4b(255, 255, 255, 255);
    processor.backTexture = [LTTexture textureWithImage:frame];
    processor.backSymmetrization = LTSymmetrizationTypeRight;
    [processor process];

    cv::Mat4b expected(2, 2);
    expected = cv::Vec4b(255, 255, 255, 255);
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 4);
  });
});

SpecEnd
