// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTDisplacementMapDrawer.h"

#import <LTKit/LTRandom.h>

#import "LTMeshProcessor.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static void LTSetMaskToHalfOnesHalfZeros(LTTexture *mask) {
  using half_float::half;

  [mask clearColor:LTVector4::ones()];
  [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::Mat1hf mat = mapped->rowRange(mapped->rows / 2, mapped->rows - 1);
    std::fill(mat.begin(), mat.end(), half(0));
  }];
}

SpecBegin(LTDisplacementMapDrawer)

__block LTTexture *displacementMap;
__block LTTexture *mask;
__block LTDisplacementMapDrawer *drawer;
__block LTReshapeBrushParams params;

static const CGSize kDeformedAreaSize = CGSizeMake(64, 128);

beforeEach(^{
  displacementMap = [LTTexture textureWithSize:CGSizeMake(9, 17)
                                   pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];
  [displacementMap clearColor:LTVector4::zeros()];

  mask = [LTTexture textureWithSize:kDeformedAreaSize pixelFormat:$(LTGLPixelFormatR16Float)
                     allocateMemory:YES];
  params = {.diameter = 1.0, .density = 1.0, .pressure = 1.0};
});

afterEach(^{
  displacementMap = nil;
  mask = nil;
  drawer = nil;
});

context(@"Initialization", ^{
  it(@"should have displacement map correctly set after initialization", ^{
    LTDisplacementMapDrawer *drawer =
        [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap
                                                deformedAreaSize:kDeformedAreaSize];
    expect($(displacementMap.image)).to.equalMat($(drawer.displacementMap.image));

    drawer = [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap mask:mask
                                                     deformedAreaSize:kDeformedAreaSize];
    expect($(displacementMap.image)).to.equalMat($(drawer.displacementMap.image));
  });
});

context(@"sanity checks", ^{
  context(@"without mask", ^{
    beforeEach(^{
      drawer = [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap
                                                       deformedAreaSize:kDeformedAreaSize];
    });

    it(@"should not deform after reshaping with a zero direction vector", ^{
      cv::Mat expected = displacementMap.image;
      [drawer reshapeWithCenter:CGPointMake(0.5, 0.5) direction:CGPointZero brushParams:params];
      expect($(displacementMap.image)).to.equalMat($(expected));
    });

    it(@"should not deform after resizing with a scale factor of 1", ^{
      cv::Mat expected = displacementMap.image;
      [drawer resizeWithCenter:CGPointMake(0.5, 0.5) scale:1 brushParams:params];
      expect($(displacementMap.image)).to.equalMat($(expected));
    });

    it(@"should not deform after unwarping the map in its neutral state", ^{
      cv::Mat expected = displacementMap.image;
      [drawer unwarpWithCenter:CGPointMake(0.75, 0.75) brushParams:params];
      expect($(displacementMap.image)).to.equalMat($(expected));
    });
  });

  context(@"with mask", ^{
     beforeEach(^{
       [mask clearColor:LTVector4::zeros()];
       drawer = [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap mask:mask
                                                        deformedAreaSize:kDeformedAreaSize];
     });

    it(@"should not deform after reshaping with a zeros mask", ^{
      cv::Mat expected = displacementMap.image;
      [drawer reshapeWithCenter:CGPointMake(0.5, 0.5) direction:CGPointMake(0.25, 0.25)
                    brushParams:params];
      expect($(displacementMap.image)).to.equalMat($(expected));
    });

    it(@"should not deform after resizing with a zeros mask", ^{
      cv::Mat expected = displacementMap.image;
      [drawer resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
      expect($(displacementMap.image)).to.equalMat($(expected));
    });

    it(@"should not deform after unwarping the map in its neutral state regardless the mask", ^{
      LTSetMaskToHalfOnesHalfZeros(mask);

      cv::Mat expected = displacementMap.image;
      [drawer unwarpWithCenter:CGPointMake(0.75, 0.75) brushParams:params];
      expect($(displacementMap.image)).to.equalMat($(expected));
    });
  });
});

context(@"transformations", ^{
  static const CGSize kInputSize = CGSizeMake(64, 128);
  static const CGSize kOutputSize = CGSizeMake(64, 128);

  __block LTMeshProcessor *meshProcessor;
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture byteRGBATextureWithSize:kInputSize];

    CGSize  meshSize = displacementMap.size - CGSizeMakeUniform(1);
    CGSize cellSize = input.size / meshSize;

    input.magFilterInterpolation = LTTextureInterpolationLinear;
    input.minFilterInterpolation = LTTextureInterpolationLinear;
    [input mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      LTRandom *random = [[LTRandom alloc] initWithSeed:0];
      cv::Mat4b mat = *mapped;
      for (int i = 0; i < meshSize.height; ++i) {
        for (int j = 0; j < meshSize.width; ++j) {
          cv::Rect rect(j * cellSize.width, i * cellSize.height, cellSize.width, cellSize.height);
          cv::Vec4b color([random randomUnsignedIntegerBelow:256],
                          [random randomUnsignedIntegerBelow:256],
                          [random randomUnsignedIntegerBelow:256], 255);
          mat(rect).setTo(color);
        }
      }
    }];

    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    meshProcessor = [[LTMeshProcessor alloc] initWithInput:input
                                   meshDisplacementTexture:displacementMap output:output];
  });

  afterEach(^{
    meshProcessor = nil;
    input = nil;
    output = nil;
  });

  context(@"without mask", ^{
    beforeEach(^{
      drawer = [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap
                                                       deformedAreaSize:kDeformedAreaSize];
    });

    it(@"should reset", ^{
      using half_float::half;

      [drawer.displacementMap clearColor:LTVector4::ones()];
      [drawer resetDisplacementMap];

      cv::Mat4hf expected(displacementMap.size.height, displacementMap.size.width,
                          cv::Vec4hf(half(0), half(0), half(0), half(0)));

      expect($(displacementMap.image)).to.equalMat($(expected));
    });

    it(@"should reshape", ^{
      [drawer reshapeWithCenter:CGPointMake(0.5, 0.5) direction:CGPointMake(0.25, 0.25)
                       brushParams:params];

      cv::Mat4b expected =
          LTLoadMat([self class], @"LTDisplacementMapDrawerReshapedWithoutMask.png");

      [meshProcessor process];
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 45);
    });

    it(@"should resize", ^{
      [drawer resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];

      cv::Mat4b expected =
          LTLoadMat([self class], @"LTDisplacementMapDrawerResizedWithoutMask.png");

      [meshProcessor process];
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should unwarp", ^{
      [drawer resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
      [drawer unwarpWithCenter:CGPointMake(0.25, 0.25) brushParams:params];

      cv::Mat4b expected =
          LTLoadMat([self class], @"LTDisplacementMapDrawerUnwarpedWithoutMask.png");

      [meshProcessor process];
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });
  });

  context(@"with mask", ^{
    beforeEach(^{
      LTSetMaskToHalfOnesHalfZeros(mask);

      drawer = [[LTDisplacementMapDrawer alloc] initWithDisplacementMap:displacementMap mask:mask
                                                       deformedAreaSize:kDeformedAreaSize];
    });

    it(@"should reset ignoring mask", ^{
      using half_float::half;

      [drawer.displacementMap clearColor:LTVector4::ones()];
      [drawer resetDisplacementMap];

      cv::Mat4hf expected(displacementMap.size.height, displacementMap.size.width,
                          cv::Vec4hf(half(0), half(0), half(0), half(0)));

      expect($(displacementMap.image)).to.equalMat($(expected));
    });

    it(@"should reshape with respect to mask", ^{
      [drawer reshapeWithCenter:CGPointMake(0.5, 0.5) direction:CGPointMake(0.25, 0.25)
                    brushParams:params];

      cv::Mat4b expected = LTLoadMat([self class], @"LTDisplacementMapDrawerReshapedWithMask.png");

      [meshProcessor process];
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should resize with respect to mask", ^{
      [drawer resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];

      cv::Mat4b expected = LTLoadMat([self class], @"LTDisplacementMapDrawerResizedWithMask.png");

      [meshProcessor process];
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should unwarp ignoring mask", ^{
      cv::Mat1hf previousMask = mask.image;
      [mask clearColor:LTVector4::ones()];
      [drawer resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
      [mask load:previousMask];
      [drawer unwarpWithCenter:CGPointMake(0.75, 0.75) brushParams:params];

      cv::Mat4b expected = LTLoadMat([self class], @"LTDisplacementMapDrawerUnwarpedWithMask.png");

      [meshProcessor process];
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });
  });
});

SpecEnd
