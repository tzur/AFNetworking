// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTMeshProcessor.h"

#import <LTKit/LTRandom.h>

#import "LTOpenCVExtensions.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTexture+Factory.h"

#import "LTMeshDrawer.h"
#import "LTMeshBaseDrawer.h"
#import "LTFbo.h"

SpecBegin(LTMeshProcessor)

__block LTTexture *input;
__block LTTexture *meshTexture;
__block LTTexture *output;

static const CGSize kUnpaddedInputSize = CGSizeMake(32, 64);
static const CGFloat kPaddingLength = 20;
static const CGSize kInputSize = CGSizeMake(32, 64) + CGSizeMakeUniform(kPaddingLength);
static const CGSize kMeshSize = CGSizeMake(4, 8);

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:kInputSize];
  meshTexture = [LTTexture textureWithSize:kMeshSize + CGSizeMakeUniform(1)
                               pixelFormat:$(LTGLPixelFormatRG16Float) allocateMemory:YES];
  [meshTexture clearWithColor:LTVector4::zeros()];
  output = [LTTexture byteRGBATextureWithSize:kInputSize];
});

afterEach(^{
  output = nil;
  input = nil;
  meshTexture = nil;
});

context(@"initialization", ^{
  it(@"should initialize with input, mesh texture and output", ^{
    LTMeshProcessor *processor = [[LTMeshProcessor alloc] initWithInput:input
                                                meshDisplacementTexture:meshTexture
                                                                 output:output];
    expect(processor.inputSize).to.equal(input.size);
    expect(processor.outputSize).to.equal(output.size);
    expect(processor.inputTexture).to.beIdenticalTo(input);
    expect(processor.outputTexture).to.beIdenticalTo(output);
    expect(processor.meshDisplacementTexture).to.beIdenticalTo(meshTexture);
  });

  it(@"should initialize with fragment source, input, mesh texture and output", ^{
    LTMeshProcessor *processor =
        [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                                meshDisplacementTexture:meshTexture output:output];
    expect(processor.inputSize).to.equal(input.size);
    expect(processor.outputSize).to.equal(output.size);
    expect(processor.inputTexture).to.beIdenticalTo(input);
    expect(processor.outputTexture).to.beIdenticalTo(output);
    expect(processor.meshDisplacementTexture).to.beIdenticalTo(meshTexture);
  });

  it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
    static LTGLPixelFormat * const kInvalidMeshPixelFormat = $(LTGLPixelFormatR16Float);

    LTTexture *invalidMeshTexture = [LTTexture textureWithSize:kMeshSize
                                                   pixelFormat:kInvalidMeshPixelFormat
                                                allocateMemory:YES];
    expect(^{
      LTMeshProcessor __unused *processor =
          [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                                  meshDisplacementTexture:invalidMeshTexture output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
    static LTGLPixelFormat * const kInvalidMeshPixelFormat = $(LTGLPixelFormatRGBA8Unorm);

    LTTexture *invalidMeshTexture = [LTTexture textureWithSize:kMeshSize
                                                   pixelFormat:kInvalidMeshPixelFormat
                                                allocateMemory:YES];
    expect(^{
      LTMeshProcessor __unused *processor =
      [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                              meshDisplacementTexture:invalidMeshTexture output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with fragment source, input, mesh source rect, mesh texture and output", ^{
    LTMeshProcessor *processor =
        [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                                 displacementSourceRect:CGRectFromSize(input.size)
                                meshDisplacementTexture:meshTexture output:output];

    expect(processor.inputSize).to.equal(input.size);
    expect(processor.outputSize).to.equal(output.size);
    expect(processor.inputTexture).to.beIdenticalTo(input);
    expect(processor.outputTexture).to.beIdenticalTo(output);
    expect(processor.meshDisplacementTexture).to.beIdenticalTo(meshTexture);
  });

  it(@"should raise when initializing with a displacement source rect that is out of bounds", ^{
    CGRect outOfBoundsDisplacementSourceRect = CGRectFromSize(input.size + CGSizeMakeUniform(1));
    expect(^{
      LTMeshProcessor __unused *processor =
          [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                                   displacementSourceRect:outOfBoundsDisplacementSourceRect
                                  meshDisplacementTexture:meshTexture output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  using half_float::half;

  __block CGSize cellSize;
  __block CGSize cellRadius;
  __block CGRect displacementSourceRect;
  __block LTMeshProcessor *processor;

  beforeEach(^{
    displacementSourceRect =
        CGRectFromOriginAndSize(CGPointMake(kPaddingLength / 2, kPaddingLength / 2),
                                kUnpaddedInputSize);
    processor = [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                                         displacementSourceRect:displacementSourceRect
                                        meshDisplacementTexture:meshTexture output:output];

    cellSize = kUnpaddedInputSize / kMeshSize;
    cellRadius = cellSize / 2;

    [input clearWithColor:LTVector4::ones()];
    input.magFilterInterpolation = LTTextureInterpolationNearest;
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    cv::Mat4b cellsMat = LTGenerateCellsMat(kUnpaddedInputSize, cellSize);
    [input mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      cellsMat.copyTo((*mapped)(LTCVRectWithCGRect(displacementSourceRect)));
    }];
  });

  afterEach(^{
    processor = nil;
  });

  context(@"passthrough fragment shader and full mesh source rect", ^{
    it(@"should process with default displacement", ^{
      [processor process];
      expect($([output image])).to.equalMat($(input.image));
    });

    it(@"should process with custom displacement", ^{
      [processor.meshDisplacementTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];

      [processor process];

      cv::Mat4b expected = [input image];

      cv::Mat4b expectedUnpadded = expected(LTCVRectWithCGRect(displacementSourceRect));
      expectedUnpadded.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expectedUnpadded.colRange(cellRadius.width, cellSize.width));
      cv::flip(expectedUnpadded, expectedUnpadded, 1);
      expectedUnpadded.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expectedUnpadded.colRange(cellRadius.width, cellSize.width));
      cv::flip(expectedUnpadded, expectedUnpadded, 1);
      expect($([output image])).to.equalMat($(expected));
    });
  });

  context(@"custom fragment shader", ^{
    static NSString * const kFragmentRedFilter =
        @"uniform sampler2D sourceTexture;"
        ""
        "varying highp vec2 vTexcoord;"
        ""
        "void main() {"
        "  gl_FragColor = vec4(0.0, texture2D(sourceTexture, vTexcoord).gb, 1.0);"
        "}";

    beforeEach(^{
      processor = [[LTMeshProcessor alloc] initWithFragmentSource:kFragmentRedFilter input:input
                                           displacementSourceRect:displacementSourceRect
                                          meshDisplacementTexture:meshTexture output:output];
    });

    afterEach(^{
      processor = nil;
    });

    it(@"should process with default displacement", ^{
      [processor process];
      cv::Mat4b expected = [input image];
      std::transform(expected.begin(), expected.end(), expected.begin(),
          [](const cv::Vec4b &value) {
            return cv::Vec4b(0, value[1], value[2], value[3]);
          });

      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should process with custom displacement", ^{
      [processor.meshDisplacementTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec2hf(half(0)));
        mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
      }];
      [processor process];

      cv::Mat4b expected = [input image];
      cv::Mat4b expectedUnpadded = expected(LTCVRectWithCGRect(displacementSourceRect));
      expectedUnpadded.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expectedUnpadded.colRange(cellRadius.width, cellSize.width));
      cv::flip(expectedUnpadded, expectedUnpadded, 1);
      expectedUnpadded.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expectedUnpadded.colRange(cellRadius.width, cellSize.width));
      cv::flip(expectedUnpadded, expectedUnpadded, 1);
      std::transform(expected.begin(), expected.end(), expected.begin(),
          [](const cv::Vec4b &value) {
            return cv::Vec4b(0, value[1], value[2], value[3]);
          });
      expect($([output image])).to.equalMat($(expected));
    });
  });
});

SpecEnd
