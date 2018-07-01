// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTModifiedLaplacianProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

/// Generates a grid of changing colors padded with 0s, creating an input with a large range of
/// gradients.
static cv::Mat4b LTStepGridMake(CGSize size) {
  cv::Mat4b grid(size.height, size.width, CV_8UC4);
  grid.setTo(cv::Vec4b(0, 0, 0, 255));

  NSUInteger cellNumber = 0;
  for (int y = 0; y < grid.rows; y += 2) {
    for (int x = 0; x < grid.cols; x +=2) {
      ++cellNumber;
      grid(y, x) = cv::Vec4b(cellNumber & 0xFF, (cellNumber >> 8) & 0xFF,
                                (cellNumber >> 16) & 0xFF, 255);
    }
  }

  return grid;
}

/// Calculate the normalized modified laplacian in 32 bit floating point precision using OpenCV.
static cv::Mat LTModifiedLaplacianOpenCV(const cv::Mat &input) {
  cv::Mat floatInput;
  LTConvertMat(input, &floatInput, CV_MAKETYPE(CV_32F, input.channels()));

  cv::Mat M = (cv::Mat_<float>(3, 1) << -1. / 4., 2. / 4., -1. / 4.);
  cv::Mat G = (cv::Mat_<float>(1, 1) << 1);

  cv::Mat Lx;
  cv::sepFilter2D(floatInput, Lx, -1, M, G, cv::Point(-1, -1), 0, cv::BORDER_REPLICATE);

  cv::Mat Ly;
  cv::sepFilter2D(floatInput, Ly, -1, G, M, cv::Point(-1, -1), 0, cv::BORDER_REPLICATE);

  cv::Mat rgbResult = cv::abs(Lx) + cv::abs(Ly);
  cv::Mat1f finalResult;
  cv::cvtColor(rgbResult, finalResult, cv::COLOR_RGBA2GRAY);

  return finalResult;
}

SpecBegin(LTModifiedLaplacianProcessor)

context(@"initialization", ^{
  __block LTTexture *input;

  beforeEach(^{
    cv::Mat4b inputImage(16, 16);
    input = [LTTexture textureWithImage:inputImage];
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    input.magFilterInterpolation = LTTextureInterpolationNearest;
  });

  afterEach(^{
    input = nil;
  });

  it(@"should initialize with textures of correct type and size", ^{
    cv::Mat1hf outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
    }).toNot.raiseAny();
  });

  it(@"should initialize with textures of correct type and size", ^{
    cv::Mat1b outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with incorrect output size", ^{
    cv::Mat1hf outputImage(16, 15);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with multiple channel output", ^{
    cv::Mat4b outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with incorrect input filters", ^{
    cv::Mat1hf outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    input.minFilterInterpolation = LTTextureInterpolationLinear;
    input.magFilterInterpolation = LTTextureInterpolationLinear;

    expect(^{
      __unused LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing natural image", ^{
  it(@"should calculate the modified laplacian map correctly in 8 bit precision", ^{
    cv::Mat inputImage = LTLoadMat([self class], @"Lena.png");

    LTTexture *input = [LTTexture textureWithImage:inputImage];
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    input.magFilterInterpolation = LTTextureInterpolationNearest;

    LTTexture *output = [LTTexture textureWithSize:input.size
                                       pixelFormat:$(LTGLPixelFormatR8Unorm)
                                    allocateMemory:YES];

    LTModifiedLaplacianProcessor *processor =
        [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
    [processor process];

    cv::Mat expected = LTModifiedLaplacianOpenCV(inputImage);

    cv::Mat outputFloat;
    LTConvertMat([output image], &outputFloat,
                 CV_MAKETYPE(expected.depth(), expected.channels()));

    expect($(outputFloat)).to.beCloseToMatWithin($(expected), 1.0 / 255.0);
  });
});

static NSString * const kModifiedLaplacianMappingExamples =
    @"Creates correct modified laplacian map";

sharedExamples(kModifiedLaplacianMappingExamples, ^(NSDictionary *data) {
  context(@"processing synthetic image", ^{
    it(@"should calculate the modified laplacian map correctly in 8 bit precision", ^{
      CGSize testSize = [data[@"size"] CGSizeValue];
      cv::Mat4b inputImage = LTStepGridMake(testSize);

      LTTexture *input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;

      LTTexture *output = [LTTexture textureWithSize:input.size
                                         pixelFormat:$(LTGLPixelFormatR8Unorm)
                                      allocateMemory:YES];

      LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
      [processor process];

      cv::Mat expected = LTModifiedLaplacianOpenCV(inputImage);

      cv::Mat outputFloat;
      LTConvertMat([output image], &outputFloat,
                   CV_MAKETYPE(expected.depth(), expected.channels()));

      expect($(outputFloat)).to.beCloseToMatWithin($(expected), 1.0 / 255.0);
    });

    it(@"should calculate the modified laplacian map correctly in half float precision", ^{
      CGSize testSize = [data[@"size"] CGSizeValue];
      cv::Mat4b inputImage = LTStepGridMake(testSize);

      LTTexture *input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;

      LTTexture *output = [LTTexture textureWithSize:input.size
                                         pixelFormat:$(LTGLPixelFormatR16Float)
                                      allocateMemory:YES];

      LTModifiedLaplacianProcessor *processor =
          [[LTModifiedLaplacianProcessor alloc] initWithTexture:input output:output];
      [processor process];

      cv::Mat expected = LTModifiedLaplacianOpenCV(inputImage);

      cv::Mat outputFloat;
      LTConvertMat([output image], &outputFloat,
                   CV_MAKETYPE(expected.depth(), expected.channels()));

      expect($(outputFloat)).to.beCloseToMatWithin($(expected), 1.0 / 255.0 / 4.0);
    });
  });
});

// Width OR height > 2048 required to test sampling accuracy due to \c vTexCoords precision limits.
itBehavesLike(kModifiedLaplacianMappingExamples, @{@"size": $(CGSizeMake(1, 4000))});

itBehavesLike(kModifiedLaplacianMappingExamples, @{@"size": $(CGSizeMake(4000, 1))});

// Larger texture creation is used to sample a wider range of values in the exposure mapping.
itBehavesLike(kModifiedLaplacianMappingExamples, @{@"size": $(CGSizeMake(256, 256))});

SpecEnd
