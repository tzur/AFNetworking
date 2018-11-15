// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianLevelFusionProcessor.h"

#import "LTHatPyramidProcessor.h"
#import "LTLaplacianLevelConstructProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTPyramidTestUtils.h"
#import "LTTexture+Factory.h"

static cv::Mat1hf LTWeightMapPatternMake(CGSize size) {
  cv::Mat1f weightsFloat(size.height, size.width, 0.0f);

  for (int y = 0; y < weightsFloat.rows; ++y) {
    int step = 1 + std::floor((weightsFloat.cols - 1) / (weightsFloat.rows - 1) * y);
    float denominator = std::ceil(weightsFloat.cols / float(step));
    float nominator = 1;

    for (int x = 0; x < weightsFloat.cols; x += step) {
      weightsFloat(y, x) = nominator / denominator;
      ++nominator;
    }
  }

  cv::Mat1hf weightsMap;
  LTConvertMat(weightsFloat, &weightsMap, CV_16F);
  return weightsMap;
}

static cv::Mat1hf LTWeightMapComplementaryMake(const cv::Mat1hf &otherWeight) {
  cv::Mat1f weightsFloat;
  LTConvertMat(otherWeight, &weightsFloat, CV_32F);
  weightsFloat = 1.0 - weightsFloat;
  cv::Mat1hf complementaryWeights;
  LTConvertMat(weightsFloat, &complementaryWeights, CV_16F);
  return complementaryWeights;
}

static cv::Mat1hf LTWeightMapCenterRectangleMake(CGSize size, unsigned int rectangleSide) {
  cv::Rect roi((size.height - rectangleSide) / 2, (size.width - rectangleSide) / 2,
               rectangleSide, rectangleSide);

  cv::Mat1f weightsFloat(size.height, size.width, 0.0f);
  weightsFloat(roi) = 1;

  cv::Mat1hf weightsMap;
  LTConvertMat(weightsFloat, &weightsMap, CV_16F);
  return weightsMap;
}

static void LTApplyNearestInterpolation(LTTexture *texture) {
  texture.minFilterInterpolation = LTTextureInterpolationNearest;
  texture.magFilterInterpolation = LTTextureInterpolationNearest;
}

SpecBegin(LTLaplacianLevelFusionProcessor)

context(@"initialization", ^{
  __block LTTexture *base;
  __block LTTexture *higher;
  __block LTTexture *weightMap;
  __block LTTexture *output;

  beforeEach(^{
    cv::Mat4b baseImage(16, 16);
    cv::Mat4b higherImage(8, 8);
    cv::Mat1hf weightsImage(16, 16);
    cv::Mat4hf outputImage(16, 16);

    base = [LTTexture textureWithImage:baseImage];
    higher = [LTTexture textureWithImage:higherImage];
    weightMap = [LTTexture textureWithImage:weightsImage];
    output = [LTTexture textureWithImage:outputImage];

    LTApplyNearestInterpolation(higher);
  });

  afterEach(^{
    base = nil;
    higher = nil;
    weightMap = nil;
    output = nil;
  });

  it(@"should initialize with proper input size and data types", ^{
    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:higher
                                                             baseWeightLevel:weightMap
                                                            addToOutputLevel:output];
    }).toNot.raiseAny();
  });

  it(@"should initialize with proper input size and data types when higher level is nil", ^{
    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:nil
                                                             baseWeightLevel:weightMap
                                                            addToOutputLevel:output];
    }).toNot.raiseAny();
  });

  it(@"should initialize with proper input size and data types using the convenience initializer",
     ^{
       expect(^{
         __unused LTLaplacianLevelFusionProcessor *processor =
            [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                               baseWeightLevel:weightMap
                                                              addToOutputLevel:output];
       }).toNot.raiseAny();
  });

  it(@"should not initialize with output size different than base size", ^{
    cv::Mat4b outputImage(16, 15);
    LTTexture *differentOutput = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:higher
                                                             baseWeightLevel:weightMap
                                                            addToOutputLevel:differentOutput];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with output laplacian level with int precision", ^{
    cv::Mat4b outputImage(16, 16);
    LTTexture *differentOutput = [LTTexture textureWithImage:outputImage];

    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:higher
                                                             baseWeightLevel:weightMap
                                                            addToOutputLevel:differentOutput];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with weights map size different than base size", ^{
    cv::Mat1hf weightsImage(16, 15);
    LTTexture *differentWeightMap = [LTTexture textureWithImage:weightsImage];

    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:higher
                                                             baseWeightLevel:differentWeightMap
                                                            addToOutputLevel:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with weights map in int precision", ^{
    cv::Mat4b weightsImage(16, 16);
    LTTexture *differentWeightMap = [LTTexture textureWithImage:weightsImage];

    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:higher
                                                             baseWeightLevel:differentWeightMap
                                                            addToOutputLevel:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with higher gaussian level with bilinear interpolation", ^{
    higher.minFilterInterpolation = LTTextureInterpolationLinear;
    higher.magFilterInterpolation = LTTextureInterpolationLinear;

    expect(^{
      __unused LTLaplacianLevelFusionProcessor *processor =
          [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:base
                                                         higherGaussianLevel:higher
                                                             baseWeightLevel:weightMap
                                                            addToOutputLevel:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  __block LTTexture *input1;
  __block LTTexture *input2;
  __block LTTexture *output;
  __block LTTexture *higherGaussianLevel1;
  __block LTTexture *higherGaussianLevel2;

  beforeEach(^{
    cv::Mat inputImage = LTLoadMat([self class], @"HorizontalStepFunction33.png");
    input1 = [LTTexture textureWithImage:inputImage];
    LTApplyNearestInterpolation(input1);

    cv::Mat inputImage2 = LTLoadMat([self class], @"VerticalStepFunction33.png");
    input2 = [LTTexture textureWithImage:inputImage2];
    LTApplyNearestInterpolation(input2);

    LTGLPixelFormat *laplacianFormat = input1.pixelFormat.components == LTGLPixelComponentsR ?
        $(LTGLPixelFormatR16Float) : $(LTGLPixelFormatRGBA16Float);

    output = [LTTexture textureWithSize:input1.size pixelFormat:laplacianFormat allocateMemory:YES];
    [output clearColor:LTVector4::zeros()];

    higherGaussianLevel1 = [LTTexture textureWithSize:std::ceil(input1.size / 2)
                                         pixelFormat:input1.pixelFormat
                                      allocateMemory:YES];
    LTApplyNearestInterpolation(higherGaussianLevel1);

    LTHatPyramidProcessor *pyramidProcessor1 =
        [[LTHatPyramidProcessor alloc] initWithInput:input1 outputs:@[higherGaussianLevel1]];
    [pyramidProcessor1 process];

    higherGaussianLevel2 = [LTTexture textureWithSize:std::ceil(input2.size / 2)
                                          pixelFormat:input2.pixelFormat
                                       allocateMemory:YES];
    LTApplyNearestInterpolation(higherGaussianLevel2);

    LTHatPyramidProcessor *pyramidProcessor2 =
        [[LTHatPyramidProcessor alloc] initWithInput:input2 outputs:@[higherGaussianLevel2]];
    [pyramidProcessor2 process];
  });

  afterEach(^{
    input1 = nil;
    input2 = nil;
    output = nil;
    higherGaussianLevel1 = nil;
    higherGaussianLevel2 = nil;
  });

  it(@"should not change output when weights are 0", ^{
    [input1 cloneTo:output];

    cv::Mat1f expectedFloat;
    LTConvertMat([output image], &expectedFloat, CV_32F);

    cv::Mat1hf weightsImage(output.size.height, output.size.width, half_float::half(0.0));
    LTTexture *weightMap = [LTTexture textureWithImage:weightsImage];

    LTLaplacianLevelFusionProcessor *processor =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input2
                                                   higherGaussianLevel:higherGaussianLevel2
                                                       baseWeightLevel:weightMap
                                                      addToOutputLevel:output];
    [processor process];

    cv::Mat1f outputFloat;
    LTConvertMat([output image], &outputFloat, CV_32F);

    expect($(outputFloat)).to.equalMat($(expectedFloat));
  });

  it(@"should blend images correctly using simple weights", ^{
    const unsigned int kRectangleSide = 7;

    cv::Mat1hf weightsImage1 = LTWeightMapCenterRectangleMake(output.size, kRectangleSide);
    LTTexture *weightMap1 = [LTTexture textureWithImage:weightsImage1];

    cv::Mat1hf weightsImage2 = LTWeightMapComplementaryMake(weightsImage1);
    LTTexture *weightMap2 = [LTTexture textureWithImage:weightsImage2];

    LTLaplacianLevelFusionProcessor *processor1 =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input1
                                                       higherGaussianLevel:higherGaussianLevel1
                                                           baseWeightLevel:weightMap1
                                                          addToOutputLevel:output];
    [processor1 process];

    LTLaplacianLevelFusionProcessor *processor2 =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input2
                                                       higherGaussianLevel:higherGaussianLevel2
                                                           baseWeightLevel:weightMap2
                                                          addToOutputLevel:output];
    [processor2 process];

    cv::Mat expectedFloat = LTLaplacianPyramidBlendOpenCV([input1 image], weightsImage1,
                                                          [input2 image], weightsImage2, 2)[0];

    cv::Mat outputFloat;
    LTConvertMat([output image], &outputFloat, CV_MAKETYPE(CV_32F, expectedFloat.channels()));

    expect($(outputFloat)).to.beCloseToMatWithin($(expectedFloat), 1.0 / 255.0);
  });

  it(@"should blend images correctly using complex weights", ^{
    cv::Mat1hf weightsImage1 = LTWeightMapPatternMake(output.size);
    LTTexture *weightMap1 = [LTTexture textureWithImage:weightsImage1];

    cv::Mat1hf weightsImage2 = LTWeightMapComplementaryMake(weightsImage1);
    LTTexture *weightMap2 = [LTTexture textureWithImage:weightsImage2];

    LTLaplacianLevelFusionProcessor *processor1 =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input1
                                                       higherGaussianLevel:higherGaussianLevel1
                                                           baseWeightLevel:weightMap1
                                                          addToOutputLevel:output];
    [processor1 process];

    LTLaplacianLevelFusionProcessor *processor2 =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input2
                                                       higherGaussianLevel:higherGaussianLevel2
                                                           baseWeightLevel:weightMap2
                                                          addToOutputLevel:output];
    [processor2 process];

    cv::Mat expectedFloat = LTLaplacianPyramidBlendOpenCV([input1 image], weightsImage1,
                                                          [input2 image], weightsImage2, 2)[0];

    cv::Mat outputFloat;
    LTConvertMat([output image], &outputFloat, CV_MAKETYPE(CV_32F, expectedFloat.channels()));

    expect($(outputFloat)).to.beCloseToMatWithin($(expectedFloat), 1.0 / 255.0);
  });

  it(@"should blend images correctly in final gaussian level", ^{
    cv::Mat1hf weightsImage1 = LTWeightMapPatternMake(output.size);
    LTTexture *weightMap1 = [LTTexture textureWithImage:weightsImage1];

    cv::Mat1hf weightsImage2 = LTWeightMapComplementaryMake(weightsImage1);
    LTTexture *weightMap2 = [LTTexture textureWithImage:weightsImage2];

    LTLaplacianLevelFusionProcessor *processor1 =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input1
                                                       higherGaussianLevel:nil
                                                           baseWeightLevel:weightMap1
                                                          addToOutputLevel:output];
    [processor1 process];

    LTLaplacianLevelFusionProcessor *processor2 =
        [[LTLaplacianLevelFusionProcessor alloc] initWithBaseGaussianLevel:input2
                                                       higherGaussianLevel:nil
                                                           baseWeightLevel:weightMap2
                                                          addToOutputLevel:output];
    [processor2 process];

    cv::Mat expectedFloat = LTLaplacianPyramidBlendOpenCV([input1 image], weightsImage1,
                                                          [input2 image], weightsImage2, 1)[0];

    cv::Mat outputFloat;
    LTConvertMat([output image], &outputFloat, CV_MAKETYPE(CV_32F, expectedFloat.channels()));

    expect($(outputFloat)).to.beCloseToMatPSNR($(expectedFloat), 50);
  });
});

SpecEnd
