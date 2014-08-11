// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTOneShotImageProcessor)

__block LTTexture *input;
__block LTTexture *auxTexture;
__block LTTexture *output;

static NSString * const kAuxiliaryTextureName = @"auxTexture";

beforeEach(^{
  input = [LTTexture textureWithSize:CGSizeMake(16, 16)
                           precision:LTTexturePrecisionByte
                              format:LTTextureFormatRGBA
                      allocateMemory:YES];

  auxTexture = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(16, 0, 0, 255))];

  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  input = nil;
  output = nil;
  auxTexture = nil;
});

context(@"intialization", ^{
  it(@"should initialize with no auxiliary textures", ^{
    expect(^{
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithVertexSource:[PassthroughVsh source]
                                                     fragmentSource:[AdderFsh source] input:input
                                                     andOutput:output];
    }).toNot.raiseAny();
  });

  it(@"should initialize with auxiliary textures", ^{
    expect(^{
      NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithVertexSource:[PassthroughVsh source]
                                                     fragmentSource:[AdderFsh source]
                                                     sourceTexture:input
                                                     auxiliaryTextures:auxiliaryTextures
                                                     andOutput:output];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  __block LTOneShotImageProcessor *processor;

  beforeEach(^{
    [input clearWithColor:GLKVector4Make(0, 0, 0, 1)];

    NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
    processor = [[LTOneShotImageProcessor alloc]
                 initWithVertexSource:[PassthroughVsh source]
                 fragmentSource:[AdderFsh source] sourceTexture:input
                 auxiliaryTextures:auxiliaryTextures
                 andOutput:output];

    processor[@"value"] = @0.5;
  });

  afterEach(^{
    processor = nil;
  });

  context(@"full rect processing", ^{
    it(@"should produce correct output", ^{
      [processor process];

      cv::Scalar expected(144, 128, 128, 255);
      expect($([output image])).to.beCloseToScalar($(expected));
    });

    it(@"should produce correct output twice", ^{
      [processor process];
      [processor process];

      cv::Scalar expected(144, 128, 128, 255);
      expect($([output image])).to.beCloseToScalar($(expected));
    });

  });

  context(@"subrect processing", ^{
    beforeEach(^{
      [output clearWithColor:GLKVector4Make(0, 0, 0, 1)];

      cv::Mat4b image(16, 16, cv::Vec4b(16, 0, 0, 255));
      image(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(0, 16, 0, 255));
      [auxTexture load:image];
    });

    it(@"should process entire rect of output", ^{
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:output];
      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:CGRectFromSize(output.size)];
      }];

      cv::Mat4b expected(16, 16, cv::Vec4b(144, 128, 128, 255));
      expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(128, 144, 128, 255));

      expect($([output image])).to.beCloseToMat($(expected));
    });

    it(@"should process subrect of the output", ^{
      input.magFilterInterpolation = LTTextureInterpolationNearest;
      auxTexture.magFilterInterpolation = LTTextureInterpolationNearest;

      LTFbo *fbo = [[LTFbo alloc] initWithTexture:output];
      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:CGRectMake(7, 7, 4, 4)];
      }];

      cv::Mat4b expected(16, 16, cv::Vec4b(144, 128, 128, 255));
      expected(cv::Rect(0, 0, 4, 4)).setTo(cv::Vec4b(128, 144, 128, 255));

      expect($([output image])).to.beCloseToMat($(expected));
    });

    it(@"should process subrect when output is of different size", ^{
      input.magFilterInterpolation = LTTextureInterpolationNearest;
      auxTexture.magFilterInterpolation = LTTextureInterpolationNearest;

      LTTexture *fboTexture = [LTTexture byteRGBATextureWithSize:input.size / 2];
      [fboTexture clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:fboTexture];
      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:CGRectMake(6, 6, 4, 4)];
      }];

      cv::Mat4b expected(8, 8, cv::Vec4b(144, 128, 128, 255));
      expected(cv::Rect(0, 0, 4, 4)).setTo(cv::Vec4b(128, 144, 128, 255));

      expect($([fboTexture image])).to.beCloseToMat($(expected));
    });
  });
});

SpecGLEnd
