// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTGLContext.h"
#import "LTGLException.h"
#import "LTGPUResourceExamples.h"
#import "LTRenderbuffer.h"
#import "LTTexture+Factory.h"

SpecBegin(LTFbo)

__block id glContext;

beforeEach(^{
  glContext = OCMPartialMock([LTGLContext currentContext]);
});

afterEach(^{
  glContext = nil;
});

context(@"texture attachment", ^{
  context(@"initialization", ^{
    it(@"should init with RGBA byte texture", ^{
      LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];

      expect(fbo.name).notTo.equal(0);
      expect(fbo.size).to.equal(texture.size);
      expect(fbo.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
    });
    
    it(@"should init with half-float RGBA texture on capable devices", ^{
      [[[glContext stub] andReturnValue:@(YES)] canRenderToHalfFloatTextures];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                       allocateMemory:YES];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];

      expect(fbo.name).notTo.equal(0);
      expect(fbo.size).to.equal(texture.size);
      expect(fbo.pixelFormat).to.equal($(LTGLPixelFormatRGBA16Float));
    });
    
    it(@"should raise with half-float RGBA texture on incapable devices", ^{
      [[[glContext stub] andReturnValue:@(NO)] canRenderToHalfFloatTextures];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                       allocateMemory:YES];

      expect(^{
        __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
      }).to.raise(kLTFboInvalidAttachmentException);
    });
    
    it(@"should init with float RGBA texture on capable devices", ^{
      [[[glContext stub] andReturnValue:@(YES)] canRenderToFloatTextures];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                       allocateMemory:YES];

      // Simulator doesn't support rendering to a colorbuffer, so no real initialization can happen.
      expect(^{
        __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
      }).toNot.raise(kLTFboInvalidAttachmentException);
    });

    it(@"should raise with float RGBA texture on incapable devices", ^{
      [[[glContext stub] andReturnValue:@(NO)] canRenderToFloatTextures];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                       allocateMemory:YES];

      expect(^{
        __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
      }).to.raise(kLTFboInvalidAttachmentException);
    });
  });

  context(@"mipmap", ^{
    __block LTTexture *texture;

    beforeEach(^{
      Matrices levels;
      for (uint diameter = 4; diameter > 0; diameter /= 2) {
        levels.push_back(cv::Mat4b(diameter, diameter));
      }

      texture = [LTTexture textureWithMipmapImages:levels];
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

context(@"renderbuffer attachment", ^{
  context(@"initialization", ^{
    __block CAEAGLLayer *drawable;
    __block LTRenderbuffer *renderbuffer;
    __block LTFbo *fbo;

    beforeEach(^{
      drawable = [CAEAGLLayer layer];
      drawable.frame = CGRectMake(0, 0, 1, 1);

      renderbuffer = [[LTRenderbuffer alloc] initWithDrawable:drawable];
      fbo = [[LTFbo alloc] initWithRenderbuffer:renderbuffer];
    });

    afterEach(^{
      drawable = nil;
      renderbuffer = nil;
      fbo = nil;
    });

    it(@"should init with renderbuffer", ^{
      expect(fbo.name).notTo.beNil();
      expect(fbo.level).to.equal(0);
      expect(fbo.size).to.equal(drawable.frame.size);
      expect(fbo.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
    });

    it(@"should not init with renderbuffer of zero size", ^{
      id renderbuffer = OCMClassMock([LTRenderbuffer class]);
      OCMStub([(LTRenderbuffer *)renderbuffer name]).andReturn(1);

      expect(^{
        LTFbo __unused *fbo = [[LTFbo alloc] initWithRenderbuffer:renderbuffer];
      }).to.raise(kLTFboInvalidAttachmentException);
    });
  });
});

context(@"clearing", ^{
  it(@"should clear texture with color", ^{
    LTVector4 value = LTVector4(0.5, 0.25, 0.5, 1.0);
    CGSize size = CGSizeMake(10, 10);
    cv::Mat expected(size.height, size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(128, 64, 128, 255));

    LTTexture *texture = [LTTexture textureWithSize:size
                                        pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                     allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo clearWithColor:value];

    cv::Mat image = [texture image];

    expect(LTFuzzyCompareMat(expected, image)).to.beTruthy();
  });

  it(@"should set texture fillColor when clearing with color", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    expect(texture.fillColor.isNull()).to.beTruthy();
    [fbo clearWithColor:LTVector4::zeros()];
    expect(texture.fillColor).to.equal(LTVector4::zeros());
  });
});

context(@"binding", ^{
  __block LTFbo *fbo;

  beforeEach(^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
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
});

SpecEnd
