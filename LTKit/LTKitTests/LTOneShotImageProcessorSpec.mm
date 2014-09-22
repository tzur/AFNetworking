// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor+Protected.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTOneShotImageProcessor)

__block LTOneShotImageProcessor *processor;
__block LTTexture *input;
__block LTTexture *auxTexture;
__block LTTexture *output;

static NSString * const kAuxiliaryTextureName = @"auxTexture";

beforeEach(^{
  input = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(16, 32, 64, 255))];
  auxTexture = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(64, 32, 16, 255))];
  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
  auxTexture = nil;
});

context(@"intialization", ^{
  it(@"should initialize with no auxiliary textures", ^{
    processor = [[LTOneShotImageProcessor alloc]
                 initWithVertexSource:[PassthroughVsh source] fragmentSource:[AdderFsh source]
                 input:input andOutput:output];
  });

  it(@"should initialize with auxiliary textures", ^{
    NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
    processor = [[LTOneShotImageProcessor alloc]
                 initWithVertexSource:[PassthroughVsh source] fragmentSource:[AdderFsh source]
                 sourceTexture:input auxiliaryTextures:auxiliaryTextures andOutput:output];
  });
  
  it(@"should create rect drawer based on given arguments", ^{
    NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
    processor = [[LTOneShotImageProcessor alloc]
                 initWithVertexSource:[PassthroughVsh source] fragmentSource:[AdderFsh source]
                 sourceTexture:input auxiliaryTextures:auxiliaryTextures andOutput:output];

    // This verifies that the processor's drawer is a rect drawer based on the given vertex and
    // fragment sources, with the correct source and auxiliary textures attached to it.
    expect(processor.drawer).to.beKindOf([LTRectDrawer class]);
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:LTVector4Zero];
    [processor.drawer drawRect:CGRectFromSize(fbo.size) inFramebuffer:fbo
                      fromRect:CGRectFromSize(input.size)];
    
    cv::Mat4b expected(16, 16, cv::Vec4b(80, 64, 80, 255));
    expect($(output.image)).to.equalMat($(expected));
  });
});

LTSpecEnd
