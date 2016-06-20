// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTHatPyramidProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static std::vector<cv::Mat1f> LTGaussianPyramidOpenCV(cv::Mat1f const &input) {
  std::vector<cv::Mat1f> gaussianPyramid;
  cv::Size size = input.size();
  int maxlevel = static_cast<int>(logf(static_cast<float>(cv::min(size.width, size.height))) /
                                  logf(2.0f));
  cv::buildPyramid(input, gaussianPyramid, maxlevel);
  return gaussianPyramid;
}

static void LTGaussianUpsamplePyramidOpenCV(std::vector<cv::Mat1f> &imagePyramid) {
  for(size_t lvl = 0; lvl < imagePyramid.size() - 1; ++lvl) {
    cv::Mat1f up;
    cv::pyrUp(imagePyramid[lvl + 1], up, imagePyramid[lvl].size());
    imagePyramid[lvl] = up;
  }
}

SpecBegin(LTHatPyramidProcessor)

context(@"initialization", ^{
  __block LTTexture *base;

  beforeEach(^{
    cv::Mat4b baseImage(16, 16);
    base = [LTTexture textureWithImage:baseImage];
  });

  afterEach(^{
    base = nil;
  });

  it(@"should initialize with textures using nearest neighbour filter", ^{
    base.minFilterInterpolation = LTTextureInterpolationNearest;
    base.magFilterInterpolation = LTTextureInterpolationNearest;
    NSArray<LTTexture *> *levels = [LTPyramidProcessor levelsForInput:base];

    expect(^{
      __unused LTHatPyramidProcessor *processor =
          [[LTHatPyramidProcessor alloc] initWithInput:base outputs:levels];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with textures using bilinear filter", ^{
    NSArray<LTTexture *> *levels = [LTPyramidProcessor levelsForInput:base];

    expect(^{
      __unused LTHatPyramidProcessor *processor =
          [[LTHatPyramidProcessor alloc] initWithInput:base outputs:levels];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kPyramidCreationExamples =
    @"Creates correct pyramid levels in down and up sampling";

sharedExamples(kPyramidCreationExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    __block cv::Mat inputImage;
    __block LTTexture *input;

    beforeEach(^{
      NSString *fileName = data[@"fileName"];
      inputImage = LTLoadMat([self class], fileName);
      input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;
    });

    afterEach(^{
      input = nil;
    });

    it(@"Should create correct gaussian pyramid", ^{
      NSArray<LTTexture *> *hatPyramid = [LTPyramidProcessor levelsForInput:input];
      LTHatPyramidProcessor *pyramidProcessor =
          [[LTHatPyramidProcessor alloc] initWithInput:input outputs:hatPyramid];
      [pyramidProcessor process];

      std::vector<cv::Mat1f> expectedPyramid = LTGaussianPyramidOpenCV(inputImage / 255.0);

      // Run loop without last texture due to different boundary condition (replicate vs symmetric)
      for (NSUInteger i = 0; i < hatPyramid.count - 1; ++i) {
        cv::Mat1b expectedImage;
        LTConvertMat(expectedPyramid[i + 1], &expectedImage, CV_8U);
        expect($([hatPyramid[i] image])).to.equalMat($(expectedImage));
      }
    });

    it(@"Should upsample between levels of the pyramid correctly", ^{
      NSArray<LTTexture *> *hatPyramid = [LTPyramidProcessor levelsForInput:input];
      LTHatPyramidProcessor *pyramidProcessor =
          [[LTHatPyramidProcessor alloc] initWithInput:input outputs:hatPyramid];
      [pyramidProcessor process];

      // Upsample the pyramid from each level to the one below it.
      NSMutableArray<LTTexture *> *hatFullPyramid =
          [[@[input] arrayByAddingObjectsFromArray:hatPyramid] mutableCopy];
      for (NSUInteger i = 0; i < hatFullPyramid.count - 1; ++i) {
        LTTexture *output = [LTTexture textureWithPropertiesOf:hatFullPyramid[i]];
        output.minFilterInterpolation = LTTextureInterpolationNearest;
        output.magFilterInterpolation = LTTextureInterpolationNearest;
        LTHatPyramidProcessor *pyramidUpsampleProcessor =
            [[LTHatPyramidProcessor alloc] initWithInput:hatFullPyramid[i + 1] outputs:@[output]];
        [pyramidUpsampleProcessor process];
        hatFullPyramid[i] = output;
      }

      std::vector<cv::Mat1f> expectedPyramid = LTGaussianPyramidOpenCV(inputImage / 255.0);
      LTGaussianUpsamplePyramidOpenCV(expectedPyramid);

      // Run loop without two last textures since upsampling propogates the boundary conditions
      // From the last texture to the one before last which differs from openCV boundary conditions.
      for (NSUInteger i = 0; i < hatFullPyramid.count - 2; ++i) {
        cv::Mat1b expectedImage;
        LTConvertMat(expectedPyramid[i], &expectedImage, CV_8U);
        expect($([hatFullPyramid[i] image])).to.beCloseToMat($(expectedImage));
      }
    });
  });
});

itBehavesLike(kPyramidCreationExamples, @{@"fileName": @"VerticalStepFunction33.png"});
itBehavesLike(kPyramidCreationExamples, @{@"fileName": @"VerticalStepFunction32.png"});
itBehavesLike(kPyramidCreationExamples, @{@"fileName": @"HorizontalStepFunction33.png"});
itBehavesLike(kPyramidCreationExamples, @{@"fileName": @"HorizontalStepFunction32.png"});

SpecEnd
