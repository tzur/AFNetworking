// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

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
__block LTProgram *program;

static NSString * const kAuxiliaryTextureName = @"auxTexture";

beforeEach(^{
  input = [LTTexture textureWithSize:CGSizeMake(1, 1)
                           precision:LTTexturePrecisionByte
                              format:LTTextureFormatRGBA
                      allocateMemory:YES];

  cv::Mat image = cv::Mat4b(1, 1);
  image.setTo(cv::Vec4b(16, 0, 0, 255));
  auxTexture = [LTTexture textureWithImage:image];

  output = [LTTexture textureWithPropertiesOf:input];

  program = [[LTProgram alloc]
             initWithVertexSource:[PassthroughVsh source]
             fragmentSource:[AdderFsh source]];
});

afterEach(^{
  input = nil;
  output = nil;
  auxTexture = nil;
  program = nil;
});

context(@"intialization", ^{
  it(@"should initialize with no auxiliary textures", ^{
    expect(^{
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithProgram:program input:input
                                                     andOutput:output];
    }).toNot.raiseAny();
  });

  it(@"should initialize with auxiliary textures", ^{
    expect(^{
      NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
      __unused LTOneShotImageProcessor *processor = [[LTOneShotImageProcessor alloc]
                                                     initWithProgram:program sourceTexture:input
                                                     auxiliaryTextures:auxiliaryTextures
                                                     andOutput:output];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  __block LTOneShotImageProcessor *processor;

  beforeEach(^{
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:input];
    [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];

    NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
    processor = [[LTOneShotImageProcessor alloc]
                 initWithProgram:program sourceTexture:input
                 auxiliaryTextures:auxiliaryTextures
                 andOutput:output];
  });

  afterEach(^{
    processor = nil;
  });

  it(@"should produce correct output", ^{
    processor[@"value"] = @0.5;

    [processor process];

    cv::Scalar expected(144, 128, 128, 255);
    expect(LTFuzzyCompareMatWithValue(expected, [output image])).to.beTruthy();
  });

  it(@"should produce correct output twice", ^{
    processor[@"value"] = @0.5;

    [processor process];
    [processor process];

    cv::Scalar expected(144, 128, 128, 255);
    expect(LTFuzzyCompareMatWithValue(expected, [output image])).to.beTruthy();
  });
});

SpecGLEnd
