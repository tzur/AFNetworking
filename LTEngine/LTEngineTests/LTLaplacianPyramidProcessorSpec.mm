// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianPyramidProcessor.h"

#import "LTPyramidTestUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTLaplacianPyramidProcessor)

context(@"initialization", ^{
  it(@"should initialize with proper input and min/mag filters", ^{
    cv::Mat4b inputImage(16, 16);
    LTTexture *input = [LTTexture textureWithImage:inputImage];
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    input.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(^{
      __unused LTLaplacianPyramidProcessor *processor =
          [[LTLaplacianPyramidProcessor alloc] initWithInputTexture:input];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with input and bilinear min/mag filters", ^{
    cv::Mat4b inputImage(16, 16);
    LTTexture *input = [LTTexture textureWithImage:inputImage];

    expect(^{
      __unused LTLaplacianPyramidProcessor *processor =
          [[LTLaplacianPyramidProcessor alloc] initWithInputTexture:input];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with outputs size larger than base size", ^{
    cv::Mat4b baseImage(16, 16);
    cv::Mat4b image1(8, 8);
    cv::Mat4b image2(16, 15);

    LTTexture *base = [LTTexture textureWithImage:baseImage];
    base.minFilterInterpolation = LTTextureInterpolationNearest;
    base.magFilterInterpolation = LTTextureInterpolationNearest;

    LTTexture *output1 = [LTTexture textureWithImage:image1];
    output1.minFilterInterpolation = LTTextureInterpolationNearest;
    output1.magFilterInterpolation = LTTextureInterpolationNearest;

    LTTexture *output2 = [LTTexture textureWithImage:image2];
    output2.minFilterInterpolation = LTTextureInterpolationNearest;
    output2.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(^{
      __unused LTLaplacianPyramidProcessor *processor =
          [[LTLaplacianPyramidProcessor alloc] initWithInputTexture:base
                                                 outputPyramidArray:@[output1, output2]];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kPyramidGenerationExamples =
    @"create proper outputs array for laplacian pyramid";

sharedExamples(kPyramidGenerationExamples, ^(NSDictionary *data) {
  context(@"output generation", ^{
    it(@"should create pyramid up to maximal level", ^{
      CGSize size = [data[@"size"] CGSizeValue];
      cv::Mat4b inputImage(size.height, size.width);
      LTTexture *input = [LTTexture textureWithImage:inputImage];

      NSArray<LTTexture *> *outputs = [LTLaplacianPyramidProcessor levelsForInput:input];
      expect(outputs.count).to.equal([data[@"expectedLevels"] unsignedIntegerValue]);
    });

    it(@"should create pyramid up to level as requested", ^{
      CGSize size = [data[@"size"] CGSizeValue];
      cv::Mat4b inputImage(size.height, size.width);
      LTTexture *input = [LTTexture textureWithImage:inputImage];

      NSArray<LTTexture *> *outputs = [LTLaplacianPyramidProcessor levelsForInput:input
                                                                        upToLevel:2];
      expect(outputs.count).to.equal(2);
    });
  });
});

itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(16, 16)),
                                            @"expectedLevels": @(4)});
itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(16, 15)),
                                            @"expectedLevels": @(3)});
itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(15, 16)),
                                            @"expectedLevels": @(3)});
itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(15, 15)),
                                            @"expectedLevels": @(3)});

static NSString * const kLaplacianPyramidConstructionExamples =
    @"Creates correct laplacian pyramid";

sharedExamples(kLaplacianPyramidConstructionExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    it(@"should create correct laplacian pyramid for given image", ^{
      NSString *fileName = data[@"fileName"];
      cv::Mat inputImage = LTLoadMat([self class], fileName);

      LTTexture *input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;

      LTLaplacianPyramidProcessor *pyramidProcessor = [[LTLaplacianPyramidProcessor alloc]
                                                       initWithInputTexture:input];
      [pyramidProcessor process];
      NSArray<LTTexture *> *laplacianPyramid = pyramidProcessor.outputLaplacianPyramid;

      cv::Mat1f inputFloat;
      LTConvertMat(inputImage, &inputFloat, CV_32F);
      std::vector<cv::Mat> expectedLaplacianPyramid = LTLaplacianPyramidOpenCV(inputFloat);

      int boundaryPixelsForRemoval = (int)[data[@"boundaryPixelsForRemoval"] unsignedIntegerValue];
      /// Loop stopping condition is determined based on boundary conditions and ROI crop.
      for (NSUInteger i = 0; i < laplacianPyramid.count -
           std::max(2.0, std::floor(std::log2(2 * boundaryPixelsForRemoval))); ++i) {
        cv::Rect roi(boundaryPixelsForRemoval, boundaryPixelsForRemoval,
                     expectedLaplacianPyramid[i].size().width - 2 * boundaryPixelsForRemoval,
                     expectedLaplacianPyramid[i].size().height - 2 * boundaryPixelsForRemoval);

        cv::Mat1f expected = expectedLaplacianPyramid[i](roi);
        cv::Mat1f outputFloat;
        LTConvertMat([laplacianPyramid[i] image](roi), &outputFloat, CV_32F);

        expect($(outputFloat)).to.beCloseToMatWithin($(expected), 1 / 255.0);
      }
    });
  });
});

itBehavesLike(kLaplacianPyramidConstructionExamples, @{@"fileName": @"VerticalStepFunction33.png",
                                                       @"boundaryPixelsForRemoval": @1});
itBehavesLike(kLaplacianPyramidConstructionExamples, @{@"fileName": @"VerticalStepFunction32.png",
                                                       @"boundaryPixelsForRemoval": @1});
itBehavesLike(kLaplacianPyramidConstructionExamples, @{@"fileName": @"HorizontalStepFunction33.png",
                                                       @"boundaryPixelsForRemoval": @1});
itBehavesLike(kLaplacianPyramidConstructionExamples, @{@"fileName": @"HorizontalStepFunction32.png",
                                                       @"boundaryPixelsForRemoval": @1});
itBehavesLike(kLaplacianPyramidConstructionExamples, @{@"fileName": @"Lena.png",
                                                       @"boundaryPixelsForRemoval": @5});

SpecEnd
