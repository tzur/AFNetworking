// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTDevice.h"
#import "LTGLTexture.h"
#import "LTGLException.h"
#import "LTGPUResourceExamples.h"
#import "LTTestUtils.h"

SpecBegin(LTFbo)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

context(@"initialization", ^{
  it(@"should init with RGBA byte texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];

    expect(fbo.name).toNot.equal(0);
  });
  
  it(@"should init with half-float RGBA texture on capable devices", ^{
    id device = [OCMockObject mockForClass:[LTDevice class]];
    [[[device stub] andReturnValue:@(YES)] canRenderToHalfFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionHalfFloat
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture device:device];

    expect(fbo.name).toNot.equal(0);
  });
  
  it(@"should raise with half-float RGBA texture on incapable devices", ^{
    id device = [OCMockObject mockForClass:[LTDevice class]];
    [[[device stub] andReturnValue:@(NO)] canRenderToHalfFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionHalfFloat
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];

    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture device:device];
    }).to.raise(kLTFboInvalidTextureException);
  });
  
  it(@"should init with float RGBA texture on capable devices", ^{
    id device = [OCMockObject mockForClass:[LTDevice class]];
    [[[device stub] andReturnValue:@(YES)] canRenderToFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionFloat
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];

    // Simulator doesn't support rendering to a colorbuffer, so no real initialization can happen.
    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture device:device];
    }).toNot.raise(kLTFboInvalidTextureException);
  });

  it(@"should raise with float RGBA texture on incapable devices", ^{
    id device = [OCMockObject mockForClass:[LTDevice class]];
    [[[device stub] andReturnValue:@(NO)] canRenderToFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionFloat
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];

    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture device:device];
    }).to.raise(kLTFboInvalidTextureException);
  });

  it(@"should not init with zero-size texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeZero
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];

    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    }).to.raise(kLTFboInvalidTextureException);
  });
});

context(@"clearing", ^{
  it(@"should clear texture with color", ^{
    GLKVector4 value = GLKVector4Make(0.5, 0.25, 0.5, 1.0);
    CGSize size = CGSizeMake(10, 10);
    cv::Mat expected(size.height, size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(128, 64, 128, 255));

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:size
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo clearWithColor:value];

    cv::Mat image = [texture image];

    expect(LTFuzzyCompareMat(expected, image)).to.beTruthy();
  });
});

context(@"binding", ^{
  __block LTFbo *fbo;

  beforeEach(^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:YES];
    fbo = [[LTFbo alloc] initWithTexture:texture];
  });

  afterEach(^{
    fbo = nil;
  });

  itShouldBehaveLike(kLTResourceExamples, ^{
    return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:fbo],
             kLTResourceExamplesOpenGLParameterName: @GL_FRAMEBUFFER_BINDING};
  });
});

SpecEnd