// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTFboAttachmentInfo.h"
#import "LTGLCheck.h"
#import "LTGLContext.h"
#import "LTGLException.h"
#import "LTGPUResourceExamples.h"
#import "LTPassthroughProcessor.h"
#import "LTRenderbuffer.h"
#import "LTTexture+Factory.h"

SpecBegin(LTFbo)

context(@"texture attachable", ^{
  context(@"initialization", ^{
    __block id glContext;

    beforeEach(^{
      glContext = OCMPartialMock([LTGLContext currentContext]);
    });

    afterEach(^{
      glContext = nil;
    });

    it(@"should init with RGBA byte texture", ^{
      LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];

      expect(fbo.name).notTo.equal(0);
      expect(fbo.size).to.equal(texture.size);
      expect(fbo.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
    });

    it(@"should init with half-float RGBA texture on capable devices", ^{
      [[[glContext stub] andReturnValue:@(YES)] canRenderToHalfFloatColorBuffers];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                       allocateMemory:YES];
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];

      expect(fbo.name).notTo.equal(0);
      expect(fbo.size).to.equal(texture.size);
      expect(fbo.pixelFormat).to.equal($(LTGLPixelFormatRGBA16Float));
    });

    it(@"should raise with half-float RGBA texture on incapable devices", ^{
      [[[glContext stub] andReturnValue:@(NO)] canRenderToHalfFloatColorBuffers];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                       allocateMemory:YES];

      expect(^{
        __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
      }).to.raise(kLTFboInvalidAttachmentException);
    });

    it(@"should init with float RGBA texture on capable devices", ^{
      [[[glContext stub] andReturnValue:@(YES)] canRenderToFloatColorBuffers];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                       allocateMemory:YES];

      // Simulator doesn't support rendering to a colorbuffer, so no real initialization can happen.
      expect(^{
        __unused LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
      }).toNot.raise(kLTFboInvalidAttachmentException);
    });

    it(@"should raise with float RGBA texture on incapable devices", ^{
      [[[glContext stub] andReturnValue:@(NO)] canRenderToFloatColorBuffers];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                          pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                       allocateMemory:YES];

      expect(^{
        auto __unused fbo = [[LTFbo alloc] initWithTexture:texture context:glContext];
      }).to.raise(kLTFboInvalidAttachmentException);
    });

    it(@"should init with attachables of different type, size and format", ^{
      auto texture = [LTTexture textureWithSize:CGSizeMake(1, 2)
                                    pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                 allocateMemory:YES];
      auto texture1 = [LTTexture textureWithSize:CGSizeMake(2, 1)
                                     pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                  allocateMemory:YES];
      auto renderbuffer = [[LTRenderbuffer alloc] initWithSize:CGSizeMake(1, 1)
                                                   pixelFormat:$(LTGLPixelFormatDepth16Unorm)];
      auto fbo = [[LTFbo alloc] initWithAttachables:@{
        @(LTFboAttachmentPointColor0): texture,
        @(LTFboAttachmentPointColor1): texture1,
        @(LTFboAttachmentPointDepth): renderbuffer
      }];

      expect(fbo.attachment).to.equal(texture);
    });

    it(@"should fail to init without attachables", ^{
      expect(^{
        auto __unused fbo = [[LTFbo alloc] initWithAttachables:@{}];
      }).to.raise(NSInvalidArgumentException);
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

it(@"should let attachables deallocate when not held strongly", ^{
  __weak LTTexture *weakTexture;
  __weak LTRenderbuffer *weakRenderbuffer;
  __weak LTFbo *weakFbo;

  @autoreleasepool {
    auto texture = [LTTexture textureWithSize:CGSizeMake(1, 2)
                                  pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                               allocateMemory:YES];
    auto renderbuffer = [[LTRenderbuffer alloc] initWithSize:CGSizeMake(1, 1)
                                                 pixelFormat:$(LTGLPixelFormatDepth16Unorm)];
    auto fbo = [[LTFbo alloc] initWithAttachables:@{
      @(LTFboAttachmentPointColor0): texture,
      @(LTFboAttachmentPointDepth): renderbuffer
    }];
    weakTexture = texture;
    weakRenderbuffer = renderbuffer;
    weakFbo = fbo;
  }

  expect(weakTexture).to.beNil();
  expect(weakRenderbuffer).to.beNil();
  expect(weakFbo).to.beNil();
});

context(@"renderbuffer attachable", ^{
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

  context(@"properties", ^{
    it(@"should return the correct attachable's size", ^{
      auto size0 = CGSizeMake(2, 2);
      auto size1 = CGSizeMake(3, 3);
      auto texture0 = [LTTexture byteRGBATextureWithSize:size0];
      auto texture1 = [LTTexture byteRGBATextureWithSize:size1];

      auto fbo = [[LTFbo alloc] initWithAttachables:@{
        @(LTFboAttachmentPointColor0): texture0,
        @(LTFboAttachmentPointColor2): texture1
      }];

      expect(fbo.size).to.equal(size0);
    });

    it(@"should return the correct attachable", ^{
      auto texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 3)];
      auto renderbuffer = [[LTRenderbuffer alloc] initWithSize:CGSizeMake(2, 1)
                                                   pixelFormat:$(LTGLPixelFormatRGBA8Unorm)];

      auto fbo = [[LTFbo alloc] initWithAttachables:@{
        @(LTFboAttachmentPointColor0): texture,
        @(LTFboAttachmentPointColor3): renderbuffer
      }];

      expect(fbo.attachment).to.equal(texture);
    });

    it(@"should return the correct attachable's pixel format", ^{
      auto size0 = CGSizeMake(2, 3);
      auto size1 = CGSizeMake(3, 2);
      auto pixelFormat0 = $(LTGLPixelFormatRGBA8Unorm);
      auto pixelFormat1 = $(LTGLPixelFormatDepth16Unorm);
      auto renderbuffer = [[LTRenderbuffer alloc] initWithSize:size0 pixelFormat:pixelFormat0];
      auto texture = [LTTexture textureWithSize:size1 pixelFormat:pixelFormat1 allocateMemory:YES];

      auto fbo = [[LTFbo alloc] initWithAttachables:@{
        @(LTFboAttachmentPointColor2): renderbuffer,
        @(LTFboAttachmentPointDepth): texture
      }];

      expect(fbo.pixelFormat).to.equal(pixelFormat0);
    });

    it(@"should return the correct attachable's level", ^{
      Matrices levels;
      for (uint diameter = 4; diameter > 0; diameter /= 2) {
        levels.push_back(cv::Mat4b(diameter, diameter));
      }
      auto texture = [LTTexture textureWithMipmapImages:levels];

      auto fbo = [[LTFbo alloc] initWithAttachmentInfos:@{
        @(LTFboAttachmentPointColor0): [LTFboAttachmentInfo withAttachable:texture level:2],
        @(LTFboAttachmentPointColor1): [LTFboAttachmentInfo withAttachable:texture level:1],
        @(LTFboAttachmentPointColor2): [LTFboAttachmentInfo withAttachable:texture level:0]
      }];

      expect(fbo.level).to.equal(2);
    });
  });
});

context(@"clearing", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [LTGLContext currentContext];
  });

  afterEach(^{
    context = nil;
  });

  it(@"should clear texture with color", ^{
    LTVector4 value = LTVector4(0.5, 0.25, 0.5, 1.0);
    CGSize size = CGSizeMake(10, 10);
    cv::Mat expected(size.height, size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(128, 64, 128, 255));

    LTTexture *texture = [LTTexture textureWithSize:size
                                        pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                     allocateMemory:YES];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo clearColor:value];

    cv::Mat image = [texture image];

    expect(LTFuzzyCompareMat(expected, image)).to.beTruthy();
  });

  it(@"should clear depth texture when clearing with clearDepth:", ^{
    GLfloat depthClearValue = 0.5;
    CGSize size = CGSizeMake(1, 1);
    auto readTexture = [LTTexture textureWithSize:size pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                    allocateMemory:YES];
    auto depthTexture = [LTTexture textureWithSize:size pixelFormat:$(LTGLPixelFormatDepth16Unorm)
                                    allocateMemory:YES];
    auto fbo = [[LTFbo alloc] initWithContext:context attachmentInfos:@{
      @(LTFboAttachmentPointDepth): [LTFboAttachmentInfo withAttachable:depthTexture]
    }];

    [fbo clearDepth:depthClearValue];
    [readTexture clearColor:LTVector4::zeros()];

    context.depthTestEnabled = YES;

    // Note depth texture can not be read due to its pixel format, hence need to convert it into
    // texture with readable pixel format.
    auto processor = [[LTPassthroughProcessor alloc] initWithInput:depthTexture output:readTexture];
    [processor process];

    expect($([readTexture image])).to.equalScalar($(cv::Scalar(128, 0, 0, 255)));
  });

  it(@"should set texture fillColor when clearing with color", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    expect(texture.fillColor.isNull()).to.beTruthy();
    [fbo clearColor:LTVector4::zeros()];
    expect(texture.fillColor).to.equal(LTVector4::zeros());
  });

  it(@"should set texture fill color when clearing with clearDepth:", ^{
    auto texture = [LTTexture textureWithSize:CGSizeMake(2, 3)
                                  pixelFormat:$(LTGLPixelFormatDepth16Unorm)
                               allocateMemory:YES];
    context.depthTestEnabled = YES;
    auto fbo = [[LTFbo alloc] initWithContext:context attachmentInfos:@{
      @(LTFboAttachmentPointDepth): [LTFboAttachmentInfo withAttachable:texture]
    }];

    expect(texture.fillColor.isNull()).to.beTruthy();
    [fbo clearDepth:0.5];
    expect(texture.fillColor).to.equal(LTVector4(0.5));
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
    return @{
      kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:fbo],
      kLTResourceExamplesOpenGLParameterName: @GL_FRAMEBUFFER_BINDING,
      kLTResourceExamplesIsResourceFunction:
          [NSValue valueWithPointer:(const void *)glIsFramebuffer]
    };
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

context(@"dispose", ^{
  __block LTFbo *fbo;
  __block LTTexture *texture;

  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
    fbo = [[LTFbo alloc] initWithTexture:texture];
  });

  it(@"should allow reusing disposed fbo name", ^{
    expect(fbo.name).notTo.equal(0);
    expect(glIsFramebuffer(fbo.name)).to.beTruthy();

    [fbo dispose];

    expect(fbo.name).to.equal(0);
    expect(^{
      LTGLCheckDbg(@"error when when disposing fbo");
    }).notTo.raiseAny();
  });

  it(@"should dispose fbo when bound", ^{
    [fbo bindAndExecute:^{
      [fbo dispose];
      expect(glIsFramebuffer(fbo.name)).to.beFalsy();
    }];
    expect(glIsFramebuffer(fbo.name)).to.beFalsy();
  });

  it(@"should have no effect when disposed multiple times", ^{
    __block GLboolean isFramebuffer;
    expect(^{
      [fbo dispose];
      [fbo dispose];
      isFramebuffer = glIsFramebuffer(fbo.name);
    }).notTo.raiseAny();
    expect(isFramebuffer).to.beFalsy();
    expect(glIsFramebuffer(fbo.name)).to.beFalsy();
  });

  it(@"should raise when clearing disposed fbo", ^{
    [fbo dispose];
    [fbo clearColor:LTVector4::zeros()];
    expect(^{
      LTGLCheckDbg(@"error when clearing disposed fbo");
    }).to.raise(kLTOpenGLRuntimeErrorException);
  });
});

SpecEnd
