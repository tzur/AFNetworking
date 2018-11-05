// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMeshBaseDrawer.h"

#import <LTKit/LTRandom.h>

#import "LTFbo.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTexture+Factory.h"
#import "LTTextureDrawerExamples.h"

static cv::Mat4b LTGenerateWireframeMat(CGSize wireframeSize, CGSize cellSize) {
  LTParameterAssert(std::round(wireframeSize) == wireframeSize);
  LTParameterAssert(std::round(cellSize) == cellSize);

  CGSize meshSize = wireframeSize / cellSize;
  LTParameterAssert(std::round(meshSize) == meshSize);

  cv::Mat4b wireframe(wireframeSize.height, wireframeSize.width, cv::Vec4b(0, 0, 0, 0));

  LTRandom *random = [[LTRandom alloc] initWithSeed:0];
  for (int i = 0; i < meshSize.height; ++i) {
    for (int j = 0; j < meshSize.width; ++j) {
      cv::Rect rect(j * cellSize.width, i * cellSize.height, cellSize.width, cellSize.height);
      cv::Vec4b color([random randomUnsignedIntegerBelow:256],
                      [random randomUnsignedIntegerBelow:256],
                      [random randomUnsignedIntegerBelow:256], 255);
      wireframe(rect).setTo(color);
      CGSize sizeDelta = CGSizeMake(j < meshSize.width - 1 ? 1 : 2,
                                    i < meshSize.height - 1 ? 1 : 2);
      rect = cv::Rect(j * cellSize.width + 1, i * cellSize.height + 1,
                      cellSize.width - sizeDelta.width, cellSize.height - sizeDelta.height);
      wireframe(rect).setTo(0);
    }
  }

  return wireframe;
}

SpecBegin(LTMeshBaseDrawer)

static const CGSize kUnpaddedInputSize = CGSizeMake(32, 64);
static const CGSize kMeshSize = CGSizeMake(4, 8);

static NSString * const kFragmentRedFilter =
    @"uniform sampler2D sourceTexture;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  gl_FragColor = vec4(0.0, texture2D(sourceTexture, vTexcoord).gb, 1.0);"
    "}";

context(@"initialization", ^{
  static const CGRect kValidMeshSourceRect = CGRectMake(10, 10, 10, 10);

  __block LTTexture *inputTexture;

  beforeEach(^{
    inputTexture = [LTTexture byteRGBATextureWithSize:kUnpaddedInputSize];
  });

  afterEach(^{
    inputTexture = nil;
  });

  it(@"should initialize with a valid mesh texture and a valid mesh source rect", ^{
    LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                            pixelFormat:$(LTGLPixelFormatRG16Float)
                                         allocateMemory:YES];
    expect(^{
      LTMeshBaseDrawer __unused *drawer =
          [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                           meshSourceRect:kValidMeshSourceRect
                                              meshTexture:meshTexture
                                           fragmentSource:[PassthroughFsh source]];
    }).notTo.raiseAny();
  });

  it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
    LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                            pixelFormat:$(LTGLPixelFormatR16Float)
                                         allocateMemory:YES];
    expect(^{
      LTMeshBaseDrawer __unused *drawer =
          [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                           meshSourceRect:kValidMeshSourceRect
                                              meshTexture:meshTexture
                                           fragmentSource:[PassthroughFsh source]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
    LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                            pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                         allocateMemory:YES];
    expect(^{
      LTMeshBaseDrawer __unused *drawer =
          [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                           meshSourceRect:kValidMeshSourceRect
                                              meshTexture:meshTexture
                                           fragmentSource:[PassthroughFsh source]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when initializing with a mesh source rect that is out of bounds", ^{
    LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                            pixelFormat:$(LTGLPixelFormatRG16Float)
                                         allocateMemory:YES];
    expect(^{
      LTMeshBaseDrawer __unused *drawer =
          [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                           meshSourceRect:CGRectMake(0, 0, 64, 64)
                                              meshTexture:meshTexture
                                           fragmentSource:[PassthroughFsh source]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  __block LTMeshBaseDrawer *drawer;

  beforeEach(^{
    LTTexture *inputTexture = [LTTexture byteRGBATextureWithSize:kUnpaddedInputSize];
    LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                            pixelFormat:$(LTGLPixelFormatRG16Float)
                                         allocateMemory:YES];

    drawer = [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                              meshSourceRect:CGRectMake(10, 10, 10, 10)
                                                 meshTexture:meshTexture
                                              fragmentSource:[PassthroughFsh source]];
  });

  afterEach(^{
    drawer = nil;
  });

  it(@"should have default properties", ^{
    expect(drawer.drawWireframe).to.beFalsy();
  });

  it(@"should set drawWireframe", ^{
    drawer.drawWireframe = YES;
    expect(drawer.drawWireframe).to.beTruthy();
  });
});

context(@"drawing on the entire source texture", ^{
  using half_float::half;

  __block LTTexture *inputTexture;
  __block LTTexture *meshTexture;
  __block CGSize cellSize;
  __block CGSize cellRadius;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block cv::Mat4b wireframe;

  beforeEach(^{
    cellSize = kUnpaddedInputSize / kMeshSize;
    cellRadius = cellSize / 2;

    inputTexture = [LTTexture textureWithImage:LTGenerateCellsMat(kUnpaddedInputSize, cellSize)];
    inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;

    wireframe = LTGenerateWireframeMat(kUnpaddedInputSize, cellSize);

    meshTexture = [LTTexture textureWithSize:kMeshSize + CGSizeMakeUniform(1)
                                 pixelFormat:$(LTGLPixelFormatRG16Float) allocateMemory:YES];
    [meshTexture clearColor:LTVector4::zeros()];

    output = [LTTexture byteRGBATextureWithSize:inputTexture.size];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearColor:LTVector4::zeros()];
  });

  afterEach(^{
    inputTexture = nil;
    meshTexture = nil;
    fbo = nil;
    output = nil;
  });

  context(@"passthrough framebuffer", ^{
    __block LTMeshBaseDrawer *drawer;

    beforeEach(^{
      drawer = [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                                meshSourceRect:CGRectFromSize(inputTexture.size)
                                                   meshTexture:meshTexture
                                                fragmentSource:[PassthroughFsh source]];
    });

    afterEach(^{
      drawer = nil;
    });

    it(@"should draw displaced texture", ^{
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];

      cv::Mat4b expected = [inputTexture image];
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expect($([output image])).to.equalMat($(expected));

      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->row(1).setTo(cv::Vec2hf(half(0), half(-0.5 / kMeshSize.height)));
        mapped->row(mapped->rows - 2).setTo(cv::Vec2hf(half(0), half(0.5 / kMeshSize.height)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];

      expected = [inputTexture image];
      expected.rowRange(cellSize.height, cellSize.height + cellRadius.height)
          .copyTo(expected.rowRange(cellRadius.height, cellSize.height));
      cv::flip(expected, expected, 0);
      expected.rowRange(cellSize.height, cellSize.height + cellRadius.height)
          .copyTo(expected.rowRange(cellRadius.height, cellSize.height));
      cv::flip(expected, expected, 0);
      expect($([output image])).to.equalMat($(expected));
    });

    // Setting \c drawWireframe generates a draw call with \c LTDrawingContextDrawModeLines mode,
    // which is loosely defined. To prevent this test falling on devices it's restricted to run on
    // simulator. This feature is used only for debug purposes and never in production.
    sit(@"should draw displaced wireframe", ^{
      drawer.drawWireframe = YES;
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];

      cv::Mat4b expected = wireframe.clone();
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width + 1)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width + 1));
      expect($([output image])).to.equalMat($(expected));

      [output clearColor:LTVector4::zeros()];
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->row(1).setTo(cv::Vec2hf(half(0), half(-0.5 / kMeshSize.height)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];

      wireframe.copyTo(expected);
      expected.rowRange(cellSize.height, cellSize.height + cellRadius.height + 1)
          .copyTo(expected.rowRange(cellRadius.height, cellSize.height + 1));
      expect($([output image])).to.equalMat($(expected));
    });

    context(@"subrects", ^{
      __block cv::Mat4b warped;

      beforeEach(^{
        [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          mapped->setTo(cv::Vec2hf(half(0)));
          mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
          mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
        }];

        [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
                fromRect:CGRectFromSize(inputTexture.size)];
        warped = [output image];
        [output clearColor:LTVector4::zeros()];
      });

      context(@"framebuffer", ^{
        it(@"should draw subrect of input to entire output", ^{
          CGRect targetRect = CGRectFromSize(fbo.size);
          CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                      inputTexture.size / 2);
          [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

          cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
          cv::Mat4b expected(output.size.height, output.size.width);
          cv::resize(subrect, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw all input to subrect of output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromSize(inputTexture.size);
          [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

          cv::Mat4b subrect(targetRect.size.height, targetRect.size.width);
          cv::resize(warped, subrect, subrect.size(), 0, 0, cv::INTER_NEAREST);
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw subrect of input to subrect of output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                      inputTexture.size / 2);
          [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

          cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          expect($([output image])).to.equalMat($(expected));
        });
      });

      context(@"screen framebuffer", ^{
        it(@"should draw subrect of input to entire output", ^{
          CGRect targetRect = CGRectFromSize(fbo.size);
          CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                      inputTexture.size / 2);
          [fbo bindAndDrawOnScreen:^{
            [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
          }];

          cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
          cv::Mat4b expected(output.size.height, output.size.width);
          cv::resize(subrect, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
          cv::flip(expected, expected, 0);
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw all input to subrect of output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromSize(inputTexture.size);
          [fbo bindAndDrawOnScreen:^{
            [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
          }];

          cv::Mat4b subrect(targetRect.size.height, targetRect.size.width);
          cv::resize(warped, subrect, subrect.size(), 0, 0, cv::INTER_NEAREST);
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          cv::flip(expected, expected, 0);
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw subrect of input to subrect of output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromOriginAndSize(CGPointMake(inputTexture.size.width / 2, 0),
                                                      inputTexture.size / 2);
          [fbo bindAndDrawOnScreen:^{
            [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
          }];

          cv::Mat4b subrect = warped(LTCVRectWithCGRect(sourceRect));
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          cv::flip(expected, expected, 0);
          expect($([output image])).to.equalMat($(expected));
        });
      });
    });
  });

  context(@"custom fragment shader", ^{
    __block LTMeshBaseDrawer *drawer;

    beforeEach(^{
      drawer = [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                                meshSourceRect:CGRectFromSize(inputTexture.size)
                                                   meshTexture:meshTexture
                                                fragmentSource:kFragmentRedFilter];
    });

    afterEach(^{
      drawer = nil;
    });

    it(@"should draw with default mesh texture", ^{
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];

      cv::Mat4b expected = [inputTexture image];
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });

      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should draw with custom mesh texture", ^{
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];

      cv::Mat4b expected = [inputTexture image];
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });

      expect($([output image])).to.equalMat($(expected));
    });
  });
});

context(@"drawing on a custom mesh source rect", ^{
  using half_float::half;

  __block LTTexture *inputTexture;
  __block CGRect meshSourceRect;
  __block LTTexture *meshTexture;
  __block CGSize cellSize;
  __block CGSize cellRadius;
  __block LTTexture *output;
  __block LTFbo *fbo;

  beforeEach(^{
    static const CGFloat kPaddingLength = 20;

    meshSourceRect = CGRectFromOriginAndSize(CGPointMake(kPaddingLength / 2, kPaddingLength / 2),
                                             kUnpaddedInputSize);
    cellSize = kUnpaddedInputSize / kMeshSize;
    cellRadius = cellSize / 2;

    cv::Mat4b inputTextureMat(kUnpaddedInputSize.height + kPaddingLength,
                              kUnpaddedInputSize.width + kPaddingLength,
                              cv::Vec4b(0, 0, 0, 0));
    cv::Mat4b cellsMat = LTGenerateCellsMat(kUnpaddedInputSize, cellSize);
    cellsMat.copyTo(inputTextureMat(LTCVRectWithCGRect(meshSourceRect)));

    inputTexture = [LTTexture textureWithImage:inputTextureMat];
    inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;

    meshTexture = [LTTexture textureWithSize:kMeshSize + CGSizeMakeUniform(1)
                                 pixelFormat:$(LTGLPixelFormatRG16Float) allocateMemory:YES];
    [meshTexture clearColor:LTVector4::zeros()];

    output = [LTTexture byteRGBATextureWithSize:kUnpaddedInputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearColor:LTVector4::zeros()];
  });

  afterEach(^{
    inputTexture = nil;
    meshTexture = nil;
    fbo = nil;
    output = nil;
  });

  context(@"passthrough framebuffer", ^{
    __block LTMeshBaseDrawer *drawer;

    beforeEach(^{
      drawer = [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                                meshSourceRect:meshSourceRect
                                                   meshTexture:meshTexture
                                                fragmentSource:[PassthroughFsh source]];
    });

    afterEach(^{
      drawer = nil;
    });

    it(@"should draw displaced texture", ^{
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo fromRect:meshSourceRect];

      cv::Mat4b expected = [inputTexture image](LTCVRectWithCGRect(meshSourceRect));
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expect($([output image])).to.equalMat($(expected));

      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->row(1).setTo(cv::Vec2hf(half(0), half(-0.5 / kMeshSize.height)));
        mapped->row(mapped->rows - 2).setTo(cv::Vec2hf(half(0), half(0.5 / kMeshSize.height)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo fromRect:meshSourceRect];

      expected = [inputTexture image](LTCVRectWithCGRect(meshSourceRect));
      expected.rowRange(cellSize.height, cellSize.height + cellRadius.height)
          .copyTo(expected.rowRange(cellRadius.height, cellSize.height));
      cv::flip(expected, expected, 0);
      expected.rowRange(cellSize.height, cellSize.height + cellRadius.height)
          .copyTo(expected.rowRange(cellRadius.height, cellSize.height));
      cv::flip(expected, expected, 0);
      expect($([output image])).to.equalMat($(expected));
    });

    context(@"invalid source rect comparing to the mesh source rect", ^{
      it(@"should raise when given source rect is not contained in the mesh source rect", ^{
        expect(^{
          [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
                  fromRect:CGRectFromSize(inputTexture.size)];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"subrects", ^{
      __block cv::Mat4b warped;

      beforeEach(^{
        [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          mapped->setTo(cv::Vec2hf(half(0)));
          mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
          mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
        }];

        [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo fromRect:meshSourceRect];
        warped = [output image];
        [output clearColor:LTVector4::zeros()];
      });

      context(@"framebuffer", ^{
        it(@"should draw a subrect of input to the entire output", ^{
          CGRect targetRect = CGRectFromSize(fbo.size);
          CGRect sourceRect = CGRectFromOriginAndSize(meshSourceRect.origin +
                                                      CGPointMake(kUnpaddedInputSize.width / 2, 0),
                                                      kUnpaddedInputSize / 2);
          [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

          CGRect wrappedSourceRect =
              CGRectFromOriginAndSize(sourceRect.origin - meshSourceRect.origin, sourceRect.size);
          cv::Mat4b subrect = warped(LTCVRectWithCGRect(wrappedSourceRect));
          cv::Mat4b expected(output.size.height, output.size.width);
          cv::resize(subrect, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw all input to a subrect of the output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromOriginAndSize(meshSourceRect.origin, kUnpaddedInputSize);
          [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

          cv::Mat4b subrect(targetRect.size.height, targetRect.size.width);
          cv::resize(warped, subrect, subrect.size(), 0, 0, cv::INTER_NEAREST);
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw a subrect of the input to a subrect of the output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromOriginAndSize(meshSourceRect.origin +
                                                      CGPointMake(kUnpaddedInputSize.width / 2, 0),
                                                      kUnpaddedInputSize / 2);
          [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

          CGRect wrappedSourceRect =
              CGRectFromOriginAndSize(sourceRect.origin - meshSourceRect.origin, sourceRect.size);
          cv::Mat4b subrect = warped(LTCVRectWithCGRect(wrappedSourceRect));
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          expect($([output image])).to.equalMat($(expected));
        });
      });

      context(@"screen framebuffer", ^{
        it(@"should draw a subrect of the input to the entire output", ^{
          CGRect targetRect = CGRectFromSize(fbo.size);
          CGRect sourceRect = CGRectFromOriginAndSize(meshSourceRect.origin +
                                                      CGPointMake(kUnpaddedInputSize.width / 2, 0),
                                                      kUnpaddedInputSize / 2);
          [fbo bindAndDrawOnScreen:^{
            [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
          }];

          CGRect wrappedSourceRect =
              CGRectFromOriginAndSize(sourceRect.origin - meshSourceRect.origin, sourceRect.size);
          cv::Mat4b subrect = warped(LTCVRectWithCGRect(wrappedSourceRect));
          cv::Mat4b expected(output.size.height, output.size.width);
          cv::resize(subrect, expected, expected.size(), 0, 0, cv::INTER_NEAREST);
          cv::flip(expected, expected, 0);
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw all input to a subrect of the output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromOriginAndSize(meshSourceRect.origin, kUnpaddedInputSize);
          [fbo bindAndDrawOnScreen:^{
            [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
          }];

          cv::Mat4b subrect(targetRect.size.height, targetRect.size.width);
          cv::resize(warped, subrect, subrect.size(), 0, 0, cv::INTER_NEAREST);
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          cv::flip(expected, expected, 0);
          expect($([output image])).to.equalMat($(expected));
        });

        it(@"should draw a subrect of the input to a subrect of the output", ^{
          CGRect targetRect = CGRectFromOriginAndSize(CGPointZero + fbo.size / 4, fbo.size / 2);
          CGRect sourceRect = CGRectFromOriginAndSize(meshSourceRect.origin +
                                                      CGPointMake(kUnpaddedInputSize.width / 2, 0),
                                                      kUnpaddedInputSize / 2);
          [fbo bindAndDrawOnScreen:^{
            [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
          }];

          CGRect wrappedSourceRect =
              CGRectFromOriginAndSize(sourceRect.origin - meshSourceRect.origin, sourceRect.size);
          cv::Mat4b subrect = warped(LTCVRectWithCGRect(wrappedSourceRect));
          cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(0, 0, 0, 0));
          subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
          cv::flip(expected, expected, 0);
          expect($([output image])).to.equalMat($(expected));
        });
      });
    });
  });

  context(@"custom fragment shader", ^{
    __block LTMeshBaseDrawer *drawer;

    beforeEach(^{
      drawer = [[LTMeshBaseDrawer alloc] initWithSourceTexture:inputTexture
                                                meshSourceRect:meshSourceRect
                                                   meshTexture:meshTexture
                                                fragmentSource:kFragmentRedFilter];
    });

    afterEach(^{
      drawer = nil;
    });

    it(@"should draw with default mesh texture", ^{
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo fromRect:meshSourceRect];

      cv::Mat4b expected = [inputTexture image](LTCVRectWithCGRect(meshSourceRect));
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });

      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should draw with custom mesh texture", ^{
      [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];
      [drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo fromRect:meshSourceRect];

      cv::Mat4b expected = [inputTexture image](LTCVRectWithCGRect(meshSourceRect));
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });

      expect($([output image])).to.equalMat($(expected));
    });
  });
});

SpecEnd
