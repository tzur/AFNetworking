// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"

SpecBegin(LTOneShotImageProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTTexture *input;
__block LTTexture *auxTexture;
__block LTTexture *output;
__block LTProgram *program;

static NSString * const kAuxiliaryTextureName = @"auxTexture";

beforeEach(^{
  input = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                  precision:LTTexturePrecisionByte
                                   channels:LTTextureChannelsRGBA
                             allocateMemory:YES];

  cv::Mat image = cv::Mat4b(1, 1);
  image.setTo(cv::Vec4b(16, 0, 0, 255));
  auxTexture = [[LTGLTexture alloc] initWithImage:image];

  output = [[LTGLTexture alloc] initWithSize:input.size
                                   precision:input.precision
                                    channels:input.channels
                              allocateMemory:YES];

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

    LTSingleTextureOutput *processed = [processor process];

    cv::Scalar expected(144, 128, 128, 255);
    expect(LTFuzzyCompareMatWithValue(expected, [processed.texture image])).to.beTruthy();
  });

  it(@"should produce correct output twice", ^{
    processor[@"value"] = @0.5;

    [processor process];
    LTSingleTextureOutput *processed = [processor process];

    cv::Scalar expected(144, 128, 128, 255);
    expect(LTFuzzyCompareMatWithValue(expected, [processed.texture image])).to.beTruthy();
  });
});

SpecEnd
