// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTMeshProcessor.h"

#import <LTKit/LTRandom.h>

#import "LTOpenCVExtensions.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTexture+Factory.h"

SpecBegin(LTMeshProcessor)

static NSString * const kFragmentRedFilter =
    @"uniform sampler2D sourceTexture;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  gl_FragColor = vec4(0.0, texture2D(sourceTexture, vTexcoord).gb, 1.0);"
    "}";

__block LTTexture *input;
__block LTTexture *output;
__block LTMeshProcessor *processor;

static const CGSize kInputSize = CGSizeMake(64, 128);
static const CGSize kOutputSize = CGSizeMake(64, 128);
static const CGSize kMeshSize = CGSizeMake(9, 17);

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:kInputSize];
  output = [LTTexture byteRGBATextureWithSize:kOutputSize];
});

afterEach(^{
  processor = nil;
  output = nil;
  input = nil;
});

context(@"initialization", ^{
  it(@"should initialize with input, mesh size and output", ^{
    processor = [[LTMeshProcessor alloc] initWithInput:input meshSize:kMeshSize output:output];
    expect(processor.meshDisplacementTexture).toNot.beNil();
    expect(processor.meshDisplacementTexture.size).to.equal(kMeshSize);
  });
  
  it(@"should initialize with fragment shader source, input, mesh size and output", ^{
    processor = [[LTMeshProcessor alloc] initWithFragmentSource:[PassthroughFsh source] input:input
                                                       meshSize:kMeshSize output:output];
    expect(processor.meshDisplacementTexture).toNot.beNil();
    expect(processor.meshDisplacementTexture.size).to.equal(kMeshSize);
  });
});

context(@"processing", ^{
  using half_float::half;
  
  __block CGSize meshSize;
  __block CGSize cellSize;
  __block CGSize cellRadius;
  __block cv::Mat4b expected;

  beforeEach(^{
    processor = [[LTMeshProcessor alloc] initWithInput:input meshSize:kMeshSize output:output];

    meshSize = processor.meshDisplacementTexture.size - CGSizeMakeUniform(1);
    cellSize = processor.inputSize / meshSize;
    cellRadius = cellSize / 2;

    input.magFilterInterpolation = LTTextureInterpolationNearest;
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    [input mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      LTRandom *random = [JSObjection defaultInjector][[LTRandom class]];
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

    expected.create(kOutputSize.height, kOutputSize.width);
    expected.setTo(cv::Vec4b(0, 0, 0, 255));
  });
  
  context(@"passthrough fragment shader", ^{
    it(@"should process with default displacement", ^{
      [processor process];
      expect($(output.image)).to.equalMat($(input.image));
    });
    
    it(@"should process with custom displacement", ^{
      [processor.meshDisplacementTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4hf(half(0)));
        mapped->col(1).setTo(cv::Vec4hf(half(-0.5 / meshSize.width), half(0), half(0), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec4hf(half(0.5 / meshSize.width), half(0),
                                                       half(0), half(0)));
      }];
      [processor process];
      
      expected = input.image;
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expect($(output.image)).to.equalMat($(expected));
    });
  });
  
  context(@"custom fragment shader", ^{
    beforeEach(^{
      processor = [[LTMeshProcessor alloc] initWithFragmentSource:kFragmentRedFilter
                                                            input:input meshSize:kMeshSize
                                                           output:output];
    });
    
    it(@"should process with default displacement", ^{
      [processor process];
      expected = input.image;
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });
      expect($(output.image)).to.equalMat($(expected));
    });
    
    it(@"should process with custom displacement", ^{
      [processor.meshDisplacementTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4hf(half(0)));
        mapped->col(1).setTo(cv::Vec4hf(half(-0.5 / meshSize.width), half(0), half(0), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec4hf(half(0.5 / meshSize.width), half(0),
                                                       half(0), half(0)));
      }];
      [processor process];
      
      expected = input.image;
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
      expect($(output.image)).to.equalMat($(expected));
    });
  });
});

SpecEnd
