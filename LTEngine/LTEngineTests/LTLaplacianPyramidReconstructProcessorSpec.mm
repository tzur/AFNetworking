// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianPyramidReconstructProcessor.h"

#import "LTLaplacianPyramidProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTLaplacianPyramidReconstructProcessor)

context(@"initialization", ^{
  it(@"should initialize with proper input", ^{
    cv::Mat4b image(16, 16);
    LTTexture *output = [LTTexture textureWithImage:image];
    output.minFilterInterpolation = LTTextureInterpolationNearest;
    output.magFilterInterpolation = LTTextureInterpolationNearest;

    NSArray<LTTexture *> *inputs = [LTLaplacianPyramidProcessor levelsForInput:output];

    expect(^{
      __unused LTLaplacianPyramidReconstructProcessor *processor =
          [[LTLaplacianPyramidReconstructProcessor alloc] initWithLaplacianPyramid:inputs
                                                                     outputTexture:output
                                                                 inPlaceProcessing:YES];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with wrong output size", ^{
    cv::Mat4b image(16, 16);
    LTTexture *output = [LTTexture textureWithImage:image];
    output.minFilterInterpolation = LTTextureInterpolationNearest;
    output.magFilterInterpolation = LTTextureInterpolationNearest;

    cv::Mat4b wrongImage(14, 16);
    LTTexture *wrongOutput = [LTTexture textureWithImage:wrongImage];

    NSArray<LTTexture *> *inputs = [LTLaplacianPyramidProcessor levelsForInput:output];

    expect(^{
      __unused LTLaplacianPyramidReconstructProcessor *processor =
          [[LTLaplacianPyramidReconstructProcessor alloc] initWithLaplacianPyramid:inputs
                                                                     outputTexture:wrongOutput
                                                                 inPlaceProcessing:YES];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kLaplacianPyramidReconstructionExamples =
    @"Correctly reconstructs a laplacian pyramid";

sharedExamples(kLaplacianPyramidReconstructionExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    __block cv::Mat inputImage;
    __block NSArray<LTTexture *> *laplacianPyramid;
    __block LTTexture *output;

    beforeEach(^{
      NSString *fileName = data[@"fileName"];
      inputImage = LTLoadMat([self class], fileName);

      LTTexture *input = [LTTexture textureWithImage:inputImage];
      input.minFilterInterpolation = LTTextureInterpolationNearest;
      input.magFilterInterpolation = LTTextureInterpolationNearest;

      LTLaplacianPyramidProcessor *pyramidConstructionProcessor =
          [[LTLaplacianPyramidProcessor alloc] initWithInputTexture:input];
      [pyramidConstructionProcessor process];

      laplacianPyramid =  pyramidConstructionProcessor.outputLaplacianPyramid;

      output = [LTTexture textureWithPropertiesOf:input];
    });

    afterEach(^{
      laplacianPyramid = nil;
      output = nil;
    });

    it(@"should reconstruct original image from its laplacian pyramid representation", ^{
      LTLaplacianPyramidReconstructProcessor *reconstructionProcessorInAuxTextures =
          [[LTLaplacianPyramidReconstructProcessor alloc] initWithLaplacianPyramid:laplacianPyramid
                                                                     outputTexture:output
                                                                 inPlaceProcessing:NO];
      [reconstructionProcessorInAuxTextures process];

      expect($([output image])).to.equalMat($(inputImage));
    });

    it(@"should reconstruct original image from its laplacian pyramid representation in place", ^{
      LTLaplacianPyramidReconstructProcessor *reconstructionProcessorInPlace =
          [[LTLaplacianPyramidReconstructProcessor alloc] initWithLaplacianPyramid:laplacianPyramid
                                                                     outputTexture:output
                                                                 inPlaceProcessing:YES];
      [reconstructionProcessorInPlace process];

      expect($([output image])).to.equalMat($(inputImage));

      // Check to see that \c process is not called twice when processing in-place.
      expect(^{
        [reconstructionProcessorInPlace process];
      }).to.raise(NSInternalInconsistencyException);
    });
  });
});

itBehavesLike(kLaplacianPyramidReconstructionExamples, @{@"fileName": @"Noise.png"});

itBehavesLike(kLaplacianPyramidReconstructionExamples, @{@"fileName": @"LenaCrop.png"});

SpecEnd
