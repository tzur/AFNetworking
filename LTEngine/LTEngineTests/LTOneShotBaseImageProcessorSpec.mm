// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTOneShotBaseImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+AdderFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"
#import "LTTextureDrawer.h"
#import "LTRectDrawer.h"

LTSpecBegin(LTOneShotBaseImageProcessor)

__block LTOneShotBaseImageProcessor *processor;
__block LTTexture *input;
__block LTTexture *auxTexture;
__block LTTexture *output;
__block id drawer;

static const CGSize kInputSize = CGSizeMake(32, 64);
static const CGSize kOutputSize = CGSizeMake(16, 32);

static NSString * const kAuxiliaryTextureName = @"auxTexture";

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:kInputSize];
  output = [LTTexture byteRGBATextureWithSize:kOutputSize];
  auxTexture = [LTTexture textureWithImage:cv::Mat4b(kInputSize.height, kInputSize.width,
                                                     cv::Vec4b(16, 0, 0, 255))];
  
  drawer = [OCMockObject niceMockForProtocol:@protocol(LTTextureDrawer)];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
  auxTexture = nil;
});

context(@"intialization", ^{
  it(@"should initialize with no auxiliary textures", ^{
    expect(^{
      processor = [[LTOneShotBaseImageProcessor alloc] initWithDrawer:drawer sourceTexture:input
                                                    auxiliaryTextures:nil andOutput:output];
    }).notTo.raiseAny();
  });
  
  it(@"should initialize with auxiliary textures", ^{
    expect(^{
      NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
      processor = [[LTOneShotBaseImageProcessor alloc] initWithDrawer:drawer sourceTexture:input
                                                    auxiliaryTextures:auxiliaryTextures
                                                            andOutput:output];
    }).notTo.raiseAny();
  });
  
  it(@"should raise when initializing without a drawer", ^{
    expect(^{
      NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
      processor = [[LTOneShotBaseImageProcessor alloc] initWithDrawer:nil sourceTexture:input
                                                    auxiliaryTextures:auxiliaryTextures
                                                            andOutput:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  beforeEach(^{
    processor = [[LTOneShotBaseImageProcessor alloc] initWithDrawer:drawer sourceTexture:input
                                                  auxiliaryTextures:nil andOutput:output];
  });
  
  it(@"should return correct textures and sizes", ^{
    expect(processor.inputTexture).to.beIdenticalTo(input);
    expect(processor.outputTexture).to.beIdenticalTo(output);
    expect(processor.inputSize).to.equal(input.size);
    expect(processor.outputSize).to.equal(output.size);
  });
});

context(@"processing", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(0, 0, 0, 255))];
    auxTexture = [LTTexture textureWithImage:cv::Mat4b(16, 16, cv::Vec4b(16, 0, 0, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    
    NSDictionary *auxiliaryTextures = @{kAuxiliaryTextureName: auxTexture};
    LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                  fragmentSource:[AdderFsh source]];
    LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:input];
    processor = [[LTOneShotBaseImageProcessor alloc] initWithDrawer:drawer sourceTexture:input
                                                  auxiliaryTextures:auxiliaryTextures
                                                          andOutput:output];
    processor[[AdderFsh value]] = @0.5;
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
      [output clearWithColor:LTVector4(0, 0, 0, 1)];
      
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
      [fboTexture clearWithColor:LTVector4(0, 0, 0, 1)];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:fboTexture];
      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:CGRectMake(6, 6, 4, 4)];
      }];
      
      cv::Mat4b expected(8, 8, cv::Vec4b(144, 128, 128, 255));
      expected(cv::Rect(0, 0, 4, 4)).setTo(cv::Vec4b(128, 144, 128, 255));
      
      expect($([fboTexture image])).to.beCloseToMat($(expected));
    });
    
    it(@"should process in rect", ^{
      [processor processInRect:CGRectMake(0, 0, 8, 8)];
      
      cv::Mat4b expected(16, 16, cv::Vec4b(0, 0, 0, 255));
      expected(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(128, 144, 128, 255));
      
      expect($([output image])).to.beCloseToMat($(expected));
    });
  });
});

LTSpecEnd
