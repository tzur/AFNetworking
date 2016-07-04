// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianLevelReconstructProcessor.h"

#import "LTHatPyramidProcessor.h"
#import "LTLaplacianLevelConstructProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTLaplacianLevelReconstructProcessor)

context(@"initialization", ^{
  __block LTTexture *base;
  __block LTTexture *higher;
  __block LTTexture *output;

  beforeEach(^{
    cv::Mat4hf baseImage(16, 16);
    cv::Mat4b higherImage(8, 8);
    cv::Mat4b outputImage(16, 16);

    base = [LTTexture textureWithImage:baseImage];
    higher = [LTTexture textureWithImage:higherImage];
    output = [LTTexture textureWithImage:outputImage];

    higher.minFilterInterpolation = LTTextureInterpolationNearest;
    higher.magFilterInterpolation = LTTextureInterpolationNearest;
  });

  afterEach(^{
    base = nil;
    higher = nil;
    output = nil;
  });

  it(@"should initialize with proper input size and data types", ^{
    expect(^{
      __unused LTLaplacianLevelReconstructProcessor *processor =
          [[LTLaplacianLevelReconstructProcessor alloc] initWithBaseLaplacianLevel:base
                                                               higherGaussianLevel:higher
                                                                     outputTexture:output];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with output size different than base size", ^{
    cv::Mat4b outputImage(16, 15);
    LTTexture *differentOutput = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTLaplacianLevelReconstructProcessor *processor =
          [[LTLaplacianLevelReconstructProcessor alloc] initWithBaseLaplacianLevel:base
                                                               higherGaussianLevel:higher
                                                                     outputTexture:differentOutput];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with base laplacian level with int precision", ^{
    cv::Mat4b baseImage(16, 16);
    LTTexture *differentBase = [LTTexture textureWithImage:baseImage];

    expect(^{
      __unused LTLaplacianLevelReconstructProcessor *processor =
          [[LTLaplacianLevelReconstructProcessor alloc] initWithBaseLaplacianLevel:differentBase
                                                               higherGaussianLevel:higher
                                                                     outputTexture:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with higher gaussian level with bilinear interpolation", ^{
    higher.minFilterInterpolation = LTTextureInterpolationLinear;
    higher.magFilterInterpolation = LTTextureInterpolationLinear;

    expect(^{
      __unused LTLaplacianLevelReconstructProcessor *processor =
          [[LTLaplacianLevelReconstructProcessor alloc] initWithBaseLaplacianLevel:base
                                                               higherGaussianLevel:higher
                                                                     outputTexture:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kLaplacianLevelReconstructionExamples =
    @"Reconstructs correct gaussian pyramid levels";

sharedExamples(kLaplacianLevelReconstructionExamples, ^(NSDictionary *data) {
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

      LTTexture *intermediateOutput = [LTTexture textureWithSize:input.size
                                                     pixelFormat:laplacianFormat
                                                  allocateMemory:YES];

      LTLaplacianLevelConstructProcessor *constructProcessor =
          [[LTLaplacianLevelConstructProcessor alloc] initWithBaseGaussianLevel:input
                                                            higherGaussianLevel:higherGaussianLevel
                                                                  outputTexture:intermediateOutput];
      [constructProcessor process];

      intermediateOutput.minFilterInterpolation = LTTextureInterpolationNearest;
      intermediateOutput.magFilterInterpolation = LTTextureInterpolationNearest;
      LTTexture *finalOutput = [LTTexture textureWithPropertiesOf:input];

      LTLaplacianLevelReconstructProcessor *reconstructProcessor =
          [[LTLaplacianLevelReconstructProcessor alloc]
           initWithBaseLaplacianLevel:intermediateOutput higherGaussianLevel:higherGaussianLevel
           outputTexture:finalOutput];

      [reconstructProcessor process];

      expect($([finalOutput image])).to.equalMat($(inputImage));
    });
  });
});

itBehavesLike(kLaplacianLevelReconstructionExamples, @{@"fileName": @"VerticalStepFunction33.png"});

itBehavesLike(kLaplacianLevelReconstructionExamples, @{@"fileName": @"VerticalStepFunction32.png"});

itBehavesLike(kLaplacianLevelReconstructionExamples,
              @{@"fileName": @"HorizontalStepFunction33.png"});

itBehavesLike(kLaplacianLevelReconstructionExamples,
              @{@"fileName": @"HorizontalStepFunction32.png"});

itBehavesLike(kLaplacianLevelReconstructionExamples, @{@"fileName": @"Lena.png"});

SpecEnd
