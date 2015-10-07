// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgramFactory.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBasicProgramFactory)

it(@"should generate program", ^{
  LTBasicProgramFactory *factory = [[LTBasicProgramFactory alloc] init];

  expect(^{
    [factory programWithVertexSource:[PassthroughVsh source]
                      fragmentSource:[PassthroughFsh source]];
  }).toNot.raiseAny();
});

SpecEnd

@interface LTNoColorInputVariableImageProcessor : LTOneShotImageProcessor
@end

@implementation LTNoColorInputVariableImageProcessor

+ (id<LTProgramFactory>)programFactory {
  return [[LTMaskableProgramFactory alloc] init];
}

@end

@interface LTColorInputVariableImageProcessor : LTOneShotImageProcessor
@end

@implementation LTColorInputVariableImageProcessor

+ (id<LTProgramFactory>)programFactory {
  return [[LTMaskableProgramFactory alloc] initWithInputColorVariableName:@"sourceColor"];
}

@end

SpecBegin(LTVerifierProgramFactory)

it(@"should raise if uniform doesn't exist", ^{
  NSSet *uniforms = [NSSet setWithArray:@[@"_foo"]];
  LTVerifierProgramFactory *factory = [[LTVerifierProgramFactory alloc]
                                       initWithRequiredUniforms:uniforms];
  expect(^{
    [factory programWithVertexSource:[PassthroughVsh source]
                      fragmentSource:[PassthroughFsh source]];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should not raise if uniform exists", ^{
  NSSet *uniforms = [NSSet setWithArray:@[@"modelview"]];
  LTVerifierProgramFactory *factory = [[LTVerifierProgramFactory alloc]
                                       initWithRequiredUniforms:uniforms];
  expect(^{
    [factory programWithVertexSource:[PassthroughVsh source]
                      fragmentSource:[PassthroughFsh source]];
  }).toNot.raiseAny();
});

SpecEnd

SpecBegin(LTMaskableProgramFactory)

context(@"construction", ^{
  it(@"should generate compilable program with no input color variable", ^{
    LTMaskableProgramFactory *factory = [[LTMaskableProgramFactory alloc] init];

    LTProgram *program = [factory programWithVertexSource:[PassthroughVsh source]
                                           fragmentSource:[PassthroughFsh source]];

    expect([program containsUniform:kLTMaskableProgramInputUniformName]).to.beTruthy();
    expect([program containsUniform:kLTMaskableProgramMaskUniformName]).to.beTruthy();
  });

  it(@"should generate compilable program with input color variable", ^{
    LTMaskableProgramFactory *factory = [[LTMaskableProgramFactory alloc]
                                         initWithInputColorVariableName:@"sourceColor"];

    LTProgram *program = [factory programWithVertexSource:[PassthroughVsh source]
                                           fragmentSource:[AdderFsh source]];

    expect([program containsUniform:kLTMaskableProgramInputUniformName]).to.beFalsy();
    expect([program containsUniform:kLTMaskableProgramMaskUniformName]).to.beTruthy();
  });

  it(@"should generate compilable program with #extension and #define", ^{
    LTMaskableProgramFactory *factory = [[LTMaskableProgramFactory alloc]
                                         initWithInputColorVariableName:@"sourceColor"];

    static NSString * const kShaderPrologue =
        @"#extension GL_EXT_shader_framebuffer_fetch : require\n"
        @"#define M_PI 3.1415\n";
    NSString *source = [kShaderPrologue stringByAppendingString:[AdderFsh source]];

    LTProgram *program = [factory programWithVertexSource:[PassthroughVsh source]
                                           fragmentSource:source];

    expect([program containsUniform:kLTMaskableProgramInputUniformName]).to.beFalsy();
    expect([program containsUniform:kLTMaskableProgramMaskUniformName]).to.beTruthy();
  });
});

context(@"mixing with no color input variable", ^{
  __block LTOneShotImageProcessor *processor;

  __block LTTexture *mask;
  __block LTTexture *output;

  beforeEach(^{
    mask = [LTTexture byteRedTextureWithSize:CGSizeMake(16, 16)];

    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(255, 0, 0, 255))];
    LTTexture *original = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(0, 255, 0, 255))];
    output = [LTTexture textureWithPropertiesOf:input];

    processor = [[LTNoColorInputVariableImageProcessor alloc]
                 initWithVertexSource:[PassthroughVsh source]
                 fragmentSource:[PassthroughFsh source]
                 input:input andOutput:output];
    [processor setAuxiliaryTexture:mask withName:kLTMaskableProgramMaskUniformName];
    [processor setAuxiliaryTexture:original withName:kLTMaskableProgramInputUniformName];
  });

  it(@"should show original when mask is black", ^{
    [mask clearWithColor:LTVector4(0, 0, 0, 0)];
    [processor process];

    expect($([output image])).to.equalScalar($(cv::Scalar(0, 255, 0, 255)));
  });

  it(@"should show fragment shader output when mask is white", ^{
    [mask clearWithColor:LTVector4(1, 1, 1, 1)];
    [processor process];

    expect($([output image])).to.equalScalar($(cv::Scalar(255, 0, 0, 255)));
  });

  it(@"should mix original and fragment shader output", ^{
    [mask clearWithColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
    [processor process];

    expect($([output image])).to.beCloseToScalar($(cv::Scalar(128, 128, 0, 255)));
  });

  afterEach(^{
    processor = nil;
    mask = nil;
    output = nil;
  });
});

context(@"mixing with color input variable", ^{
  __block LTOneShotImageProcessor *processor;

  __block LTTexture *mask;
  __block LTTexture *output;

  beforeEach(^{
    mask = [LTTexture byteRedTextureWithSize:CGSizeMake(16, 16)];

    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(255, 0, 0, 255))];
    output = [LTTexture textureWithPropertiesOf:input];

    processor = [[LTColorInputVariableImageProcessor alloc]
                 initWithVertexSource:[PassthroughVsh source]
                 fragmentSource:[AdderFsh source]
                 input:input andOutput:output];
    [processor setAuxiliaryTexture:mask withName:kLTMaskableProgramMaskUniformName];

    processor[[AdderFsh value]] = @0.5;
  });

  it(@"should show original when mask is black", ^{
    [mask clearWithColor:LTVector4(0, 0, 0, 0)];
    [processor process];

    expect($([output image])).to.equalScalar($(cv::Scalar(255, 0, 0, 255)));
  });

  it(@"should show fragment shader output when mask is white", ^{
    [mask clearWithColor:LTVector4(1, 1, 1, 1)];
    [processor process];

    expect($([output image])).to.equalScalar($(cv::Scalar(255, 128, 128, 255)));
  });

  it(@"should mix original and fragment shader output", ^{
    [mask clearWithColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
    [processor process];

    expect($([output image])).to.beCloseToScalar($(cv::Scalar(255, 64, 64, 255)));
  });

  afterEach(^{
    processor = nil;
    mask = nil;
    output = nil;
  });
});

SpecEnd
