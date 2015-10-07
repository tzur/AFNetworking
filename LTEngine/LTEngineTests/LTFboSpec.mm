// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTGLException.h"
#import "LTGPUResourceExamples.h"

SpecBegin(LTFbo)

__block id glContext;

beforeEach(^{
  glContext = OCMPartialMock([LTGLContext currentContext]);
});

afterEach(^{
  glContext = nil;
});

context(@"initialization", ^{
  it(@"should init with RGBA byte texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initByteRGBAWithSize:CGSizeMake(1, 1)];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];

    expect(fbo.name).toNot.equal(0);
  });
  
  it(@"should init with half-float RGBA texture on capable devices", ^{
    [[[glContext stub] andReturnValue:@(YES)] canRenderToHalfFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionHalfFloat
                                                    format:LTTextureFormatRGBA
                                            allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];

    expect(fbo.name).toNot.equal(0);
  });
  
  it(@"should raise with half-float RGBA texture on incapable devices", ^{
    [[[glContext stub] andReturnValue:@(NO)] canRenderToHalfFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionHalfFloat
                                                    format:LTTextureFormatRGBA
                                            allocateMemory:YES];

    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
    }).to.raise(kLTFboInvalidTextureException);
  });
  
  it(@"should init with float RGBA texture on capable devices", ^{
    [[[glContext stub] andReturnValue:@(YES)] canRenderToFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionFloat
                                                    format:LTTextureFormatRGBA
                                            allocateMemory:YES];

    // Simulator doesn't support rendering to a colorbuffer, so no real initialization can happen.
    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
    }).toNot.raise(kLTFboInvalidTextureException);
  });

  it(@"should raise with float RGBA texture on incapable devices", ^{
    [[[glContext stub] andReturnValue:@(NO)] canRenderToFloatTextures];

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionFloat
                                                    format:LTTextureFormatRGBA
                                            allocateMemory:YES];

    expect(^{
      __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
    }).to.raise(kLTFboInvalidTextureException);
  });

  context(@"mipmap", ^{
    __block LTTexture *texture;

    beforeEach(^{
      Matrices levels;
      for (uint diameter = 4; diameter > 0; diameter /= 2) {
        levels.push_back(cv::Mat4b(diameter, diameter));
      }

      texture = [[LTGLTexture alloc] initWithMipmapImages:levels];
    });

    afterEach(^{
      texture = nil;
    });

    it(@"should init with a valid mipmap level", ^{
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
      expect(fbo.name).toNot.equal(0);
      expect(fbo.level).to.equal(0);

      fbo = [[LTFbo alloc] initWithTexture:texture level:0];
      expect(fbo.name).toNot.equal(0);
      expect(fbo.level).to.equal(0);

      fbo = [[LTFbo alloc] initWithTexture:texture level:1];
      expect(fbo.name).toNot.equal(0);
      expect(fbo.level).to.equal(1);

      fbo = [[LTFbo alloc] initWithTexture:texture level:2];
      expect(fbo.name).toNot.equal(0);
      expect(fbo.level).to.equal(2);
    });
    
    it(@"should raise with invalid mipmap level", ^{
      expect(^{
        LTFbo __unused *fbo = [[LTFbo alloc] initWithTexture:texture level:3];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"clearing", ^{
  it(@"should clear texture with color", ^{
    LTVector4 value = LTVector4(0.5, 0.25, 0.5, 1.0);
    CGSize size = CGSizeMake(10, 10);
    cv::Mat expected(size.height, size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(128, 64, 128, 255));

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:size
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA
                                            allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo clearWithColor:value];

    cv::Mat image = [texture image];

    expect(LTFuzzyCompareMat(expected, image)).to.beTruthy();
  });

  it(@"should set texture fillColor when clearing with color", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMakeUniform(16)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    expect(texture.fillColor.isNull()).to.beTruthy();
    [fbo clearWithColor:LTVector4Zero];
    expect(texture.fillColor).to.equal(LTVector4Zero);
  });
});

context(@"binding", ^{
  __block LTFbo *fbo;

  beforeEach(^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionByte
                                                    format:LTTextureFormatRGBA
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

  it(@"should disable scissor test while bound", ^{
    [LTGLContext currentContext].scissorTestEnabled = YES;
    [fbo bindAndExecute:^{
      expect([LTGLContext currentContext].scissorTestEnabled).to.beFalsy();
    }];
    expect([LTGLContext currentContext].scissorTestEnabled).to.beTruthy();
  });

  it(@"should not render to screen while bound", ^{
    [LTGLContext currentContext].renderingToScreen = YES;
    [fbo bindAndExecute:^{
      expect([LTGLContext currentContext].renderingToScreen).to.beFalsy();
    }];
    expect([LTGLContext currentContext].renderingToScreen).to.beTruthy();
  });

  it(@"should set texture fillColor to null on bindAndDraw", ^{
    [fbo clearWithColor:LTVector4One];
    expect(fbo.texture.fillColor.isNull()).to.beFalsy();
    [fbo bindAndDraw:^{}];
    expect(fbo.texture.fillColor.isNull()).to.beTruthy();
  });
});

SpecEnd
