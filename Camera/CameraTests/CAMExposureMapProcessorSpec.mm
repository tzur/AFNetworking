// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMExposureMapProcessor.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTEngine/LTTexture+Factory.h>

/// Generates a grid of changing colors padded with 0s, creating an input with a large range of
/// gradients.
static void CAMGridExposureMake(CGSize size, cv::Mat4b *grid, cv::Mat1hf *exposureMap) {
  grid->create(cv::Size(size.width, size.height));
  grid->setTo(cv::Vec4b(0, 0, 0, 255));
  exposureMap->create(cv::Size(size.width, size.height));
  exposureMap->setTo(cv::Scalar(0));

  NSUInteger cellNumber = 0;
  for (int y = 0; y < grid->rows; y += 2) {
    for (int x = 0; x < grid->cols; x += 2) {
      ++cellNumber;
      (*grid)(y, x) = cv::Vec4b(cellNumber & 0xFF, (cellNumber >> 8) & 0xFF,
                                (cellNumber >> 16) & 0xFF, 255);

      cv::Vec3f floatRGB = cv::Vec3f((cellNumber & 0xFF) / 255.0f - 0.5f,
                                     ((cellNumber >> 8) & 0xFF) / 255.0f - 0.5f,
                                     ((cellNumber >> 16) & 0xFF) / 255.0f - 0.5f);
      cv::pow(floatRGB, 2.0f, floatRGB);
      floatRGB = -floatRGB / 0.08f;
      cv::exp(floatRGB, floatRGB);

      (*exposureMap)(y, x) = floatRGB[0] * floatRGB[1] * floatRGB[2];
    }
  }
}

SpecBegin(CAMExposureMapProcessor)

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
      __unused CAMExposureMapProcessor *processor =
          [[CAMExposureMapProcessor alloc] initWithTexture:input output:output];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with incorrect output size", ^{
    cv::Mat4hf outputImage(16, 15);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused CAMExposureMapProcessor *processor =
          [[CAMExposureMapProcessor alloc] initWithTexture:input output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with incorrect output type", ^{
    cv::Mat4b outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused CAMExposureMapProcessor *processor =
          [[CAMExposureMapProcessor alloc] initWithTexture:input output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with incorrect input filters", ^{
    cv::Mat1hf outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    input.minFilterInterpolation = LTTextureInterpolationLinear;
    input.magFilterInterpolation = LTTextureInterpolationLinear;

    expect(^{
      __unused CAMExposureMapProcessor *processor =
      [[CAMExposureMapProcessor alloc] initWithTexture:input output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kExposureMappingExamples =
    @"Creates correct exposure map";

sharedExamples(kExposureMappingExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    it(@"should calculate the exposure map correctly", ^{
      cv::Mat1hf exposureMap;
      cv::Mat4b inputImage;
      CGSize testSize = [data[@"size"] CGSizeValue];
      CAMGridExposureMake(testSize, &inputImage, &exposureMap);

      LTTexture *input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;
      LTTexture *output = [LTTexture textureWithSize:input.size pixelFormat:$(LTGLPixelFormatR16Float)
                                      allocateMemory:YES];

      CAMExposureMapProcessor *processor =
      [[CAMExposureMapProcessor alloc] initWithTexture:input output:output];
      [processor process];

      expect($([output image])).to.beCloseToMatWithin($(exposureMap), @0.0001);
    });
  });
});

// Width OR height > 2048 required to test sampling accuracy due to \c vTexCoords precision limits.
itBehavesLike(kExposureMappingExamples, @{@"size": $(CGSizeMake(1, 4000))});
itBehavesLike(kExposureMappingExamples, @{@"size": $(CGSizeMake(4000, 1))});
// Larger texture creation is used to sample a wider range of values in the exposure mapping.
itBehavesLike(kExposureMappingExamples, @{@"size": $(CGSizeMake(256, 256))});

SpecEnd
