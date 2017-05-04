// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianLevelConstructProcessor.h"

#import "LTHatPyramidProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTPyramidTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(LTLaplacianLevelConstructProcessor)

context(@"initialization", ^{
  __block LTTexture *base;
  __block LTTexture *higher;

  beforeEach(^{
    cv::Mat4b baseImage(16, 16);
    cv::Mat4b higherImage(8, 8);

    base = [LTTexture textureWithImage:baseImage];
    higher = [LTTexture textureWithImage:higherImage];

    higher.minFilterInterpolation = LTTextureInterpolationNearest;
    higher.magFilterInterpolation = LTTextureInterpolationNearest;
  });

  afterEach(^{
    base = nil;
    higher = nil;
  });

  it(@"should initialize with proper input size and data types", ^{
    cv::Mat4hf outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTLaplacianLevelConstructProcessor *processor =
          [[LTLaplacianLevelConstructProcessor alloc] initWithBaseGaussianLevel:base
                                                            higherGaussianLevel:higher
                                                                  outputTexture:output];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with output size different than base size", ^{
    cv::Mat4hf outputImage(16, 15);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTLaplacianLevelConstructProcessor *processor =
          [[LTLaplacianLevelConstructProcessor alloc] initWithBaseGaussianLevel:base
                                                            higherGaussianLevel:higher
                                                                  outputTexture:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with output with int precision", ^{
    cv::Mat4b outputImage(16, 16);
    LTTexture *output = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTLaplacianLevelConstructProcessor *processor =
          [[LTLaplacianLevelConstructProcessor alloc] initWithBaseGaussianLevel:base
                                                            higherGaussianLevel:higher
                                                                  outputTexture:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kLaplacianLevelConstructionExamples =
    @"Creates correct laplacian pyramid levels";

sharedExamples(kLaplacianLevelConstructionExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    it(@"should create correct laplacian pyramid level for given image", ^{
      NSString *fileName = data[@"fileName"];
      cv::Mat inputImage = LTLoadMat([self class], fileName);
      LTTexture *input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;

      LTTexture *higherGaussianLevel = [LTTexture textureWithSize:std::ceil(input.size / 2)
                                                      pixelFormat:input.pixelFormat
                                                   allocateMemory:YES];
      higherGaussianLevel.minFilterInterpolation = LTTextureInterpolationNearest;
      higherGaussianLevel.magFilterInterpolation = LTTextureInterpolationNearest;

      LTHatPyramidProcessor *pyramidProcessor =
          [[LTHatPyramidProcessor alloc] initWithInput:input outputs:@[higherGaussianLevel]];
      [pyramidProcessor process];

      LTGLPixelFormat *laplacianFormat = input.pixelFormat.components == LTGLPixelComponentsR ?
          $(LTGLPixelFormatR16Float) : $(LTGLPixelFormatRGBA16Float);

      LTTexture *output = [LTTexture textureWithSize:input.size
                                         pixelFormat:laplacianFormat
                                      allocateMemory:YES];

      LTLaplacianLevelConstructProcessor *processor =
          [[LTLaplacianLevelConstructProcessor alloc] initWithBaseGaussianLevel:input
                                                            higherGaussianLevel:higherGaussianLevel
                                                                  outputTexture:output];
      [processor process];

      int boundaryPixelsForRemoval = (int)[data[@"boundaryPixelsForRemoval"] unsignedIntegerValue];
      cv::Rect roi(boundaryPixelsForRemoval, boundaryPixelsForRemoval,
                   inputImage.size().width - 2 * boundaryPixelsForRemoval,
                   inputImage.size().height - 2 * boundaryPixelsForRemoval);

      cv::Mat outputFloat;
      LTConvertMat([output image](roi), &outputFloat, CV_MAKETYPE(CV_32F, inputImage.channels()));

      cv::Mat inputFloat;
      LTConvertMat(inputImage, &inputFloat, CV_MAKETYPE(CV_32F, inputImage.channels()));
      std::vector<cv::Mat> expectedLaplacianPyramid = LTLaplacianPyramidOpenCV(inputFloat, 2);
      cv::Mat expected = expectedLaplacianPyramid[0](roi);

      expect($(outputFloat)).to.beCloseToMatWithin($(expected), 1 / 255.0);
    });
  });
});

itBehavesLike(kLaplacianLevelConstructionExamples, @{@"fileName": @"VerticalStepFunction33.png",
                                                     @"boundaryPixelsForRemoval": @0});
itBehavesLike(kLaplacianLevelConstructionExamples, @{@"fileName": @"VerticalStepFunction32.png",
                                                     @"boundaryPixelsForRemoval": @0});
itBehavesLike(kLaplacianLevelConstructionExamples, @{@"fileName": @"HorizontalStepFunction33.png",
                                                     @"boundaryPixelsForRemoval": @0});
itBehavesLike(kLaplacianLevelConstructionExamples, @{@"fileName": @"HorizontalStepFunction32.png",
                                                     @"boundaryPixelsForRemoval": @0});
itBehavesLike(kLaplacianLevelConstructionExamples, @{@"fileName": @"Lena.png",
                                                     @"boundaryPixelsForRemoval": @5});

SpecEnd
