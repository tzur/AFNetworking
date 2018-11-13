// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUTProcessor.h"

#import "LT3DLUT.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LT3DLUTProcessor)

context(@"initialization", ^{
  it(@"should initialize lookupTable property to identity LUT", ^{
    LTGLPixelFormat *inputPixelFormat = $(LTGLPixelFormatRGBA8Unorm);
    LTTexture *input = [LTTexture textureWithSize:CGSizeMake(10, 10) pixelFormat:inputPixelFormat
                                   allocateMemory:YES];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];
    expect(lutProcessor.lookupTable).to.equal([LT3DLUT identity]);
  });
});

context(@"texture formats", ^{
  __block cv::Mat1b blackMat1channel;
  __block cv::Mat4b blackMat4channels;

  __block LT3DLUT *whiteLut;
  beforeEach(^{
    blackMat1channel = cv::Mat1b(1, 1);
    blackMat1channel(0, 0) = 0;

    blackMat4channels = cv::Mat4b(1, 1);
    blackMat4channels(0, 0) = cv::Vec4b(0, 0, 0, 255);

    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(cv::Vec4b(255, 255, 255, 255)));
    whiteLut = [LT3DLUT lutFromPackedMat:lutPackedMat];
  });

  afterEach(^{
    whiteLut = nil;
  });

  it(@"should handle single channel input texture", ^{
    LTTexture *input = [LTTexture textureWithImage:blackMat1channel];
    LTTexture *output = [LTTexture textureWithImage:blackMat4channels];

    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];
    lutProcessor.lookupTable = whiteLut;
    [lutProcessor process];

    cv::Mat4b expected(1, 1);
    expected(0, 0) = cv::Vec4b(255, 255, 255, 255);
    expect($(output.image)).to.equalMat($(expected));
  });

  it(@"should handle single channel output texture", ^{
    LTTexture *input = [LTTexture textureWithImage:blackMat4channels];
    LTTexture *output = [LTTexture textureWithImage:blackMat1channel];

    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];
    lutProcessor.lookupTable = whiteLut;
    [lutProcessor process];

    cv::Mat1b expected(1, 1);
    expected(0, 0) = 255;
    expect($(output.image)).to.equalMat($(expected));
  });
});

context(@"shader tests", ^{
  __block cv::Vec4b blackColor;
  __block cv::Vec4b whiteColor;
  __block cv::Vec4b grayColor;

  __block cv::Mat4b blackPixelMat;
  __block cv::Mat4b grayPixelMat;
  __block cv::Mat4b whitePixelMat;

  beforeEach(^{
    blackColor = cv::Vec4b(0, 0, 0, 255);
    grayColor = cv::Vec4b(127, 127, 127, 255);
    whiteColor = cv::Vec4b(255, 255, 255, 255);

    blackPixelMat = cv::Mat4b(1, 1, cv::Scalar(blackColor));
    grayPixelMat = cv::Mat4b(1, 1, cv::Scalar(grayColor));
    whitePixelMat = cv::Mat4b(1, 1, cv::Scalar(whiteColor));
  });

  it(@"should apply identity LUT on an input image correctly", ^{
    cv::Mat randomColorsImage = LTGenerateCellsMat(CGSizeMakeUniform(1024), CGSizeMakeUniform(1));
    LTTexture *colorsTexture = [LTTexture textureWithImage:randomColorsImage];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:colorsTexture];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:colorsTexture
                                                                      output:outputTexture];
    lutProcessor.lookupTable = [LT3DLUT identity];

    [lutProcessor process];
    expect($(outputTexture.image)).to.beCloseToMatPSNR($(colorsTexture.image), 50);
  });

  it(@"should take a precise value from the LUT when no interpolation is needed", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat(0, 0) = cv::Vec4b(blackColor);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    LTTexture *input = [LTTexture textureWithImage:blackPixelMat];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    expect($(output.image)).to.equalMat($(blackPixelMat));
  });

  it(@"should interpolate on the r channel correctly", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat(0, 0) = cv::Vec4b(blackColor);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(127, 0, 0, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    expect($(output.image)).to.beCloseToMatPSNR($(grayPixelMat), 48);
  });

  it(@"should interpolate on the g channel correctly", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(blackColor);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(0, 127, 0, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    expect($(output.image)).to.beCloseToMatPSNR($(grayPixelMat), 48);
  });

  it(@"should interpolate on the b channel correctly", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat(0, 0) = cv::Vec4b(blackColor);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(0, 0, 127, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    expect($(output.image)).to.equalMat($(grayPixelMat));
  });

  it(@"should interpolate on r and g channels correctly", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat(0, 0) = cv::Vec4b(1, 1, 1, 255);
    lutPackedMat(0, 1) = cv::Vec4b(3, 3, 3, 255);
    lutPackedMat(1, 0) = cv::Vec4b(5, 5, 5, 255);
    lutPackedMat(1, 1) = cv::Vec4b(7, 7, 7, 255);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(127, 127, 0, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    cv::Mat4b averagePixel(1, 1, cv::Scalar(4, 4, 4, 255));
    expect($(output.image)).to.equalMat($(averagePixel));
  });

  it(@"should interpolate on r and b channels correctly", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat(0, 0) = cv::Vec4b(1, 1, 1, 255);
    lutPackedMat(0, 1) = cv::Vec4b(3, 3, 3, 255);
    lutPackedMat(2, 0) = cv::Vec4b(5, 5, 5, 255);
    lutPackedMat(2, 1) = cv::Vec4b(7, 7, 7, 255);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(127, 0, 127, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    cv::Mat4b averagePixel(1, 1, cv::Scalar(4, 4, 4, 255));
    expect($(output.image)).to.equalMat($(averagePixel));
  });

  it(@"should interpolate on g and b channels correctly", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    lutPackedMat(0, 0) = cv::Vec4b(1, 1, 1, 255);
    lutPackedMat(1, 0) = cv::Vec4b(3, 3, 3, 255);
    lutPackedMat(2, 0) = cv::Vec4b(5, 5, 5, 255);
    lutPackedMat(3, 0) = cv::Vec4b(7, 7, 7, 255);
    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(0, 127, 127, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    cv::Mat4b averagePixel(1, 1, cv::Scalar(4, 4, 4, 255));
    expect($(output.image)).to.equalMat($(averagePixel));
  });

  it(@"should interpolate on r, g and b channels correctly", ^{
    int matDims[]{2, 2, 2};
    cv::Mat4b lattice(3, matDims);
    for (int z = 0; z < 2; ++z) {
      for (int y = 0; y < 2; ++y) {
        for (int x = 0; x < 2; ++x) {
          char value = 2 * (4 * z + 2 * y + x);
          lattice(z, y, x) = cv::Vec4b(value, value, value, 255);
        }
      }
    }

    LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:lattice];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(127, 127, 127, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    cv::Mat4b averagePixel(1, 1, cv::Scalar(7, 7, 7, 255));
    expect($(output.image)).to.equalMat($(averagePixel));
  });

  it(@"should not interpolate pixel color on a slice edge with its neighbor on another slice", ^{
    cv::Mat4b lutPackedMat(4, 2, cv::Scalar(whiteColor));
    cv::Mat blackRect(2, 2, CV_8UC4, cv::Scalar(blackColor));
    blackRect.copyTo(lutPackedMat(cv::Rect(0, 0, 2, 2)));

    LT3DLUT *lut = [LT3DLUT lutFromPackedMat:lutPackedMat];

    cv::Mat4b inputPixel(1, 1, cv::Scalar(127, 254, 0, 255));
    LTTexture *input = [LTTexture textureWithImage:inputPixel];
    LTTexture *output = [LTTexture textureWithImage:whitePixelMat];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    expect($(output.image)).to.equalMat($(blackPixelMat));
  });

  it(@"should process LUTs with different lattice sizes correctly", ^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Scalar(whiteColor))];
    LTTexture *output = [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Scalar(whiteColor))];
    LT3DLUTProcessor *lutProcessor = [[LT3DLUTProcessor alloc] initWithInput:input output:output];

    int lutLatticeDims[]{2, 3, 5};
    cv::Mat4b lutLattice(3, lutLatticeDims);
    lutLattice = cv::Scalar(whiteColor);
    lutLattice(1, 2, 4) = cv::Vec4b(0, 0, 0, 255);
    LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:lutLattice];
    lutProcessor.lookupTable = lut;
    [lutProcessor process];

    cv::Mat4b blackColorMat(1, 1, cv::Scalar(cv::Vec4b(0, 0, 0, 255)));
    expect($(output.image)).to.equalMat($(blackColorMat));
  });
});

SpecEnd
