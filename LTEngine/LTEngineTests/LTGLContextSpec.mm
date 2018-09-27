// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import "LTFbo.h"
#import "LTFboAttachmentInfo.h"
#import "LTGLContext+Internal.h"
#import "LTGLKitExtensions.h"
#import "LTGLTexture.h"
#import "LTOpenCVExtensions.h"
#import "LTPassthroughProcessor.h"
#import "LTTexture+Factory.h"

/// Object implementing \c LTGPUResource protocol, used for testing purpose. When created registers
/// itself as a resource of the current context.
@interface LTGLContextResource : NSObject <LTGPUResource>
@property (readonly, nonatomic) GLuint name;
@property (readonly, nonatomic, nullable) LTGLContext *context;
@end

@implementation LTGLContextResource

- (instancetype)initWithName:(GLuint)name context:(LTGLContext *)context {
  if (self = [super init]) {
    _name = name;
    _context = context;
    [self.context addResource:self];
  }
  return self;
}

+ (instancetype)resourceWithName:(GLuint)name {
  return [[LTGLContextResource alloc] initWithName:name context:[LTGLContext currentContext]];
}

- (void)dealloc {
  [self.context removeResource:self];
}

- (void)bind {
  LTMethodNotImplemented();
}

- (void)unbind {
  LTMethodNotImplemented();
}

- (void)bindAndExecute:(__unused NS_NOESCAPE LTVoidBlock)block {
  LTMethodNotImplemented();
}

- (void)dispose {
  LTMethodNotImplemented();
}

@end

SpecBegin(LTGLContext)

sharedExamplesFor(@"having default opengl values", ^(NSDictionary *data) {
  it(@"should have default opengl values", ^{
    LTGLContext *context = data[@"context"];

    LTGLContextBlendFuncArgs blendFunc = context.blendFunc;
    expect(blendFunc.sourceRGB).to.equal(GL_ONE);
    expect(blendFunc.destinationRGB).to.equal(GL_ZERO);
    expect(blendFunc.sourceAlpha).to.equal(GL_ONE);
    expect(blendFunc.destinationAlpha).to.equal(GL_ZERO);

    LTGLContextBlendEquationArgs blendEquation = context.blendEquation;
    expect(blendEquation.equationRGB).to.equal(GL_FUNC_ADD);
    expect(blendEquation.equationAlpha).to.equal(GL_FUNC_ADD);

    expect(context.scissorBox).to.equal(CGRectZero);

    expect(context.scissorTestEnabled).to.beFalsy();
    expect(context.renderingToScreen).to.beFalsy();
    expect(context.blendEnabled).to.beFalsy();
    expect(context.faceCullingEnabled).to.beFalsy();
    expect(context.depthTestEnabled).to.beFalsy();
    expect(context.scissorTestEnabled).to.beFalsy();
    expect(context.stencilTestEnabled).to.beFalsy();
    expect(context.ditheringEnabled).to.beTruthy();
    expect(context.clockwiseFrontFacingPolygons).to.beFalsy();

    expect(context.packAlignment).to.equal(4);
    expect(context.unpackAlignment).to.equal(4);

    LTGLDepthRange mapping = context.depthRange;
    expect(mapping.nearPlane).to.equal(0);
    expect(mapping.farPlane).to.equal(1);
    expect(context.depthMask).to.beTruthy();
    expect(context.depthFunc).to.equal(GL_LESS);
  });
});

context(@"initialization", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
  });

  afterEach(^{
    context = nil;
  });

  it(@"should initialize correctly without sharegroup", ^{
    expect(context.context).toNot.beNil();
    expect(context.fboPool).toNot.beNil();
    expect(context.programPool).toNot.beNil();
  });

  it(@"should initialize correctly with sharegroup", ^{
    LTGLContext *sharedContext = [[LTGLContext alloc]
                                  initWithSharegroup:context.context.sharegroup];
    expect(sharedContext.context).toNot.beNil();
    expect(sharedContext.context.sharegroup).to.equal(sharedContext.context.sharegroup);
    expect(sharedContext.fboPool).toNot.beNil();
    expect(sharedContext.programPool).toNot.beNil();
  });

  it(@"should initialize with nil sharegroup", ^{
    LTGLContext *contextWithNilSharegrop = [[LTGLContext alloc] initWithSharegroup:nil];
    expect(contextWithNilSharegrop.context).toNot.beNil();
  });
});

context(@"setting context", ^{
  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  it(@"should set context with valid context", ^{
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];

    expect([LTGLContext currentContext]).to.equal(context);
  });

  it(@"should clear context with nil context", ^{
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
    [LTGLContext setCurrentContext:nil];

    expect([LTGLContext currentContext]).to.beNil();
  });

  it(@"should not allow changing properties while context is not set", ^{
    LTGLContext *context = [[LTGLContext alloc] init];

    expect(^{
      context.blendEnabled = YES;
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should not allow execution while context is not set", ^{
    LTGLContext *context = [[LTGLContext alloc] init];

    expect(^{
      [context executeAndPreserveState:^(LTGLContext *context) {
        context.blendEnabled = YES;
      }];
    }).to.raise(NSInternalInconsistencyException);
  });

  // TODO: (yaron) decide if we want this capability.
  pending(@"should not allow context switch while executing");
});

context(@"context values", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });

  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  itShouldBehaveLike(@"having default opengl values", ^{
    return @{@"context": context};
  });

  it(@"should set blend functions", ^{
    LTGLContextBlendFuncArgs expected = {
      LTGLContextBlendFuncOneMinusDstAlpha,
      LTGLContextBlendFuncOneMinusDstAlpha,
      LTGLContextBlendFuncOneMinusDstAlpha,
      LTGLContextBlendFuncOneMinusDstAlpha
    };
    context.blendFunc = expected;

    LTGLContextBlendFuncArgs actual = context.blendFunc;
    expect(actual.sourceRGB).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
    expect(actual.destinationRGB).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
    expect(actual.sourceAlpha).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
    expect(actual.destinationAlpha).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);

    GLint blendFuncSourceRGB, blendFuncDestinationRGB;
    GLint blendFuncSourceAlpha, blendFuncDestinationAlpha;

    glGetIntegerv(GL_BLEND_SRC_RGB, &blendFuncSourceRGB);
    glGetIntegerv(GL_BLEND_DST_RGB, &blendFuncDestinationRGB);
    glGetIntegerv(GL_BLEND_SRC_ALPHA, &blendFuncSourceAlpha);
    glGetIntegerv(GL_BLEND_DST_ALPHA, &blendFuncDestinationAlpha);

    expect(blendFuncSourceRGB).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
    expect(blendFuncDestinationRGB).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
    expect(blendFuncSourceAlpha).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
    expect(blendFuncDestinationAlpha).to.equal(LTGLContextBlendFuncOneMinusDstAlpha);
  });

  it(@"should set blend equations", ^{
    LTGLContextBlendEquationArgs expected = {
      LTGLContextBlendEquationReverseSubtract,
      LTGLContextBlendEquationReverseSubtract
    };
    context.blendEquation = expected;

    LTGLContextBlendEquationArgs actual = context.blendEquation;
    expect(actual.equationRGB).to.equal(LTGLContextBlendEquationReverseSubtract);
    expect(actual.equationAlpha).to.equal(LTGLContextBlendEquationReverseSubtract);

    GLint blendEquationRGB, blendEquationAlpha;

    glGetIntegerv(GL_BLEND_EQUATION_RGB, &blendEquationRGB);
    glGetIntegerv(GL_BLEND_EQUATION_ALPHA, &blendEquationAlpha);

    expect(blendEquationRGB).to.equal(LTGLContextBlendEquationReverseSubtract);
    expect(blendEquationAlpha).to.equal(LTGLContextBlendEquationReverseSubtract);
  });

  it(@"should set scissor box", ^{
    const CGRect expected = CGRectMake(1, 2, 3, 4);
    context.scissorBox = expected;

    CGRect actual = context.scissorBox;
    expect(actual).to.equal(expected);

    GLint scissorBox[4];
    glGetIntegerv(GL_SCISSOR_BOX, scissorBox);
    CGRect scissorBoxRect = CGRectMake(scissorBox[0], scissorBox[1], scissorBox[2], scissorBox[3]);
    expect(scissorBoxRect).to.equal(expected);
  });

  it(@"should set rendering to screen", ^{
    context.renderingToScreen = YES;
    expect(context.renderingToScreen).to.beTruthy();
  });

  it(@"should set blending", ^{
    context.blendEnabled = YES;

    expect(context.blendEnabled).to.beTruthy();
    expect(glIsEnabled(GL_BLEND)).to.beTruthy();
  });

  it(@"should set face culling", ^{
    context.faceCullingEnabled = YES;

    expect(context.faceCullingEnabled).to.beTruthy();
    expect(glIsEnabled(GL_CULL_FACE)).to.beTruthy();
  });

  it(@"should set depth test", ^{
    context.depthTestEnabled = YES;

    expect(context.depthTestEnabled).to.beTruthy();
    expect(glIsEnabled(GL_DEPTH_TEST)).to.beTruthy();
  });

  it(@"should set scissor test", ^{
    context.scissorTestEnabled = YES;

    expect(context.scissorTestEnabled).to.beTruthy();
    expect(glIsEnabled(GL_SCISSOR_TEST)).to.beTruthy();
  });

  it(@"should set stencil test", ^{
    context.stencilTestEnabled = YES;

    expect(context.stencilTestEnabled).to.beTruthy();
    expect(glIsEnabled(GL_STENCIL_TEST)).to.beTruthy();
  });

  it(@"should set dithering", ^{
    context.ditheringEnabled = NO;

    expect(context.ditheringEnabled).to.beFalsy();
    expect(glIsEnabled(GL_DITHER)).to.beFalsy();
  });

  it(@"should set front facing polygon direction", ^{
    context.clockwiseFrontFacingPolygons = YES;

    expect(context.clockwiseFrontFacingPolygons).to.beTruthy();
    GLint frontFace;
    glGetIntegerv(GL_FRONT_FACE, &frontFace);
    expect(frontFace).to.equal(GL_CW);
  });

  it(@"should set pack alignment", ^{
    context.packAlignment = 1;

    expect(context.packAlignment).to.equal(1);
    GLint packAlignment;
    glGetIntegerv(GL_PACK_ALIGNMENT, &packAlignment);
    expect(packAlignment).to.equal(1);
  });

  it(@"should set unpack alignment", ^{
    context.unpackAlignment = 1;

    expect(context.unpackAlignment).to.equal(1);
    GLint unpackAlignment;
    glGetIntegerv(GL_UNPACK_ALIGNMENT, &unpackAlignment);
    expect(unpackAlignment).to.equal(1);
  });

  it(@"should set depth range", ^{
    LTGLDepthRange expected = {.nearPlane = 0.25, .farPlane = 0.5};
    context.depthRange = expected;

    LTGLDepthRange actual = context.depthRange;

    expect(expected.nearPlane).to.equal(actual.nearPlane);
    expect(expected.farPlane).to.equal(actual.farPlane);

    GLfloat actualReadMapping[2];
    glGetFloatv(GL_DEPTH_RANGE, actualReadMapping);
    expect(expected.nearPlane).to.beCloseTo(actualReadMapping[0]);
    expect(expected.farPlane).to.beCloseTo(actualReadMapping[1]);
  });

  it(@"should set depth mask", ^{
    context.depthMask = NO;
    expect(context.depthMask).to.beFalsy();

    GLboolean enabled;
    glGetBooleanv(GL_DEPTH_WRITEMASK, &enabled);
    expect((BOOL)enabled).to.beFalsy();
  });

  it(@"should set depth func", ^{
    LTGLFunction expected = LTGLFunctionNever;
    context.depthFunc = expected;
    expect(expected).to.equal(GL_NEVER);

    GLint actual;
    glGetIntegerv(GL_DEPTH_FUNC, &actual);
    expect(expected).to.equal((LTGLFunction)actual);
  });
});

context(@"execution", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });

  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  // State preserving.
  itShouldBehaveLike(@"having default opengl values", ^{
    [context executeAndPreserveState:^(LTGLContext *context) {
      LTGLContextBlendFuncArgs blendFunc = {
        LTGLContextBlendFuncOneMinusDstAlpha,
        LTGLContextBlendFuncOneMinusDstAlpha,
        LTGLContextBlendFuncOneMinusDstAlpha,
        LTGLContextBlendFuncOneMinusDstAlpha
      };
      context.blendFunc = blendFunc;

      LTGLContextBlendEquationArgs blendEquation = {
        LTGLContextBlendEquationReverseSubtract,
        LTGLContextBlendEquationReverseSubtract
      };
      context.blendEquation = blendEquation;

      context.scissorBox = CGRectMake(1, 2, 3, 4);

      context.renderingToScreen = !context.renderingToScreen;
      context.blendEnabled = !context.blendEnabled;
      context.faceCullingEnabled = !context.faceCullingEnabled;
      context.depthTestEnabled = !context.depthTestEnabled;
      context.scissorTestEnabled = !context.scissorTestEnabled;
      context.stencilTestEnabled = !context.stencilTestEnabled;
      context.ditheringEnabled = !context.ditheringEnabled;
      context.clockwiseFrontFacingPolygons = !context.clockwiseFrontFacingPolygons;

      context.packAlignment = 1;
      context.unpackAlignment = 1;

      context.depthRange = {.nearPlane = 0.25, .farPlane = 0.5};
      context.depthMask = !context.depthMask;
      context.depthFunc = LTGLFunctionEqual;
    }];

    return @{@"context": context};
  });

  it(@"should support recursive execution", ^{
    [context executeAndPreserveState:^(LTGLContext *context) {
      context.blendEnabled = YES;

      [context executeAndPreserveState:^(LTGLContext *context) {
        context.blendEnabled = NO;
        expect(context.blendEnabled).to.beFalsy();
      }];

      expect(context.blendEnabled).to.beTruthy();
    }];

    expect(context.blendEnabled).to.beFalsy();
  });

  it(@"should clear the color buffers", ^{
    const LTVector4 kBlue(0, 0, 1, 1);

    auto texture = [[LTGLTexture alloc] initWithImage:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    auto fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo bindAndDraw:^{
      [[LTGLContext currentContext] clearColor:kBlue];
    }];

    LTVector4 charBlue(kBlue * 255);
    cv::Mat4b expected(texture.image.rows, texture.image.cols,
                       cv::Vec4b(charBlue.r(), charBlue.g(), charBlue.b(), charBlue.a()));
    expect(LTFuzzyCompareMat(expected, [texture image])).to.beTruthy();
  });

  it(@"should clear the color buffers leaving the clearColor unchanged", ^{
    const LTVector4 kColor1 = LTVector4(1, 0, 0, 1);
    const LTVector4 kColor2 = LTVector4(0, 1, 0, 1);
    LTVector4 clearColor;

    auto texture = [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    auto fbo = [[LTFbo alloc] initWithTexture:texture];

    glClearColor(kColor1.r(), kColor1.g(), kColor1.b(), kColor1.a());
    [fbo bindAndDraw:^{
      [[LTGLContext currentContext] clearColor:kColor2];
    }];

    glGetFloatv(GL_COLOR_CLEAR_VALUE, clearColor.data());
    expect(clearColor).to.equal(kColor1);
  });

  it(@"should clear depth buffer", ^{
    CGSize size = CGSizeMake(1, 1);
    auto depthTexture = [LTTexture textureWithSize:size pixelFormat:$(LTGLPixelFormatDepth16Unorm)
                                    allocateMemory:YES];
    auto fbo = [[LTFbo alloc] initWithContext:context attachmentInfos:@{
      @(LTFboAttachmentPointDepth): [LTFboAttachmentInfo withAttachable:depthTexture]
    }];

    auto readTexture = [LTTexture textureWithSize:size pixelFormat:$(LTGLPixelFormatR16Float)
                                   allocateMemory:YES];
    [readTexture clearColor:LTVector4::zeros()];

    GLfloat clearValue = 0.5;
    cv::Mat1hf expected = cv::Mat1hf(size.height, size.width) << half_float::half(clearValue);

    context.depthTestEnabled = YES;
    [fbo bindAndExecute:^{
      [context clearDepth:clearValue];
    }];

    // Note depth texture can not be read due to its pixel format, hence need to convert it into
    // texture with readable pixel format.
    auto processor = [[LTPassthroughProcessor alloc] initWithInput:depthTexture output:readTexture];
    [processor process];

    expect($([readTexture image])).to.equalMat($(expected));
  });

  it(@"should clear the depth buffer leaving the depth clear value unchanged", ^{
    const GLfloat kValue1 = 0.5;
    const GLfloat kValue2 = 0.25;
    GLfloat clearValue;

    auto texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                  pixelFormat:$(LTGLPixelFormatDepth16Unorm)
                               allocateMemory:YES];
    auto fbo = [[LTFbo alloc] initWithContext:context attachmentInfos:@{
      @(LTFboAttachmentPointDepth): [LTFboAttachmentInfo withAttachable:texture]
    }];

    glClearDepthf(kValue1);
    [fbo bindAndExecute:^{
      [context clearDepth:kValue2];
    }];

    glGetFloatv(GL_DEPTH_CLEAR_VALUE, &clearValue);
    expect(clearValue).to.equal(kValue1);
  });
});

context(@"resource tracking", ^{
  __block LTGLContext *glContext;

  beforeEach(^{
    glContext = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:glContext];
  });

  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  it(@"should allow releasing the resource when not referenced", ^{
    __weak LTGLContextResource *weakResource;

    @autoreleasepool {
      auto resource = [LTGLContextResource resourceWithName:1];
      weakResource = resource;
      expect(weakResource).notTo.beNil();
    }
    expect(weakResource).to.beNil();
  });

  it(@"should keep the resource count up to date", ^{
    expect(glContext.resources).to.haveCountOf(0);

    @autoreleasepool {
      __unused auto resource = [LTGLContextResource resourceWithName:1];
      expect(glContext.resources).to.haveCountOf(1);

      @autoreleasepool {
        __unused auto resource2 = [LTGLContextResource resourceWithName:2];
        expect(glContext.resources).to.haveCountOf(2);
      }

      expect(glContext.resources).to.haveCountOf(1);
    }

    expect(glContext.resources).to.haveCountOf(0);
  });

  it(@"should track multiple allocated resources", ^{
    auto resource1 = [LTGLContextResource resourceWithName:1];
    auto resource2 = [LTGLContextResource resourceWithName:2];
    auto resource3 = [LTGLContextResource resourceWithName:3];

    expect(glContext.resources).to.haveACountOf(3);
    expect(glContext.resources).to.contain(resource1);
    expect(glContext.resources).to.contain(resource2);
    expect(glContext.resources).to.contain(resource3);
  });

  it(@"should deallocate resource from its creation context when other context is set", ^{
    LTGLContext *otherContext;

    @autoreleasepool {
      __unused auto resource = [LTGLContextResource resourceWithName:1];

      otherContext = [[LTGLContext alloc] init];
      [LTGLContext setCurrentContext:otherContext];

      expect(otherContext.resources).to.haveCountOf(0);
      expect(glContext.resources).to.haveCountOf(1);
    }

    expect(glContext.resources).to.haveCountOf(0);
    expect([LTGLContext currentContext]).to.equal(otherContext);
  });

  it(@"should release all weakly held resources when context deallocates", ^{
    __weak LTGLContext *weakContext;
    __weak LTGLContextResource *weakResource0;
    __weak LTGLContextResource *weakResource1;

    @autoreleasepool {
      auto context = [[LTGLContext alloc] init];
      [LTGLContext setCurrentContext:context];

      auto texture0 = [LTGLContextResource resourceWithName:1];
      auto texture1 = [LTGLContextResource resourceWithName:2];

      weakContext = context;
      weakResource0 = texture0;
      weakResource1 = texture1;
      [LTGLContext setCurrentContext:nil];
    }

    expect(weakContext).to.beNil();
    expect(weakResource0).to.beNil();
    expect(weakResource1).to.beNil();
  });

  it(@"should not release weakly held context while resource is alive", ^{
    __weak LTGLContext *weakContext;
    LTGLContextResource *resource;

    @autoreleasepool {
      auto context = [[LTGLContext alloc] init];
      [LTGLContext setCurrentContext:context];

      resource = [LTGLContextResource resourceWithName:1];
      weakContext = context;
      [LTGLContext setCurrentContext:nil];
    }

    expect(weakContext).notTo.beNil();
    expect(resource).notTo.beNil();
  });
});

context(@"context switch", ^{
  __block LTGLContext *context;
  __block LTGLContext *otherContext;
  __block dispatch_queue_t queue;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];

    queue = dispatch_queue_create("com.lightricks.LTGLContextSpec-queue", DISPATCH_QUEUE_SERIAL);
    otherContext = [[LTGLContext alloc] initWithSharegroup:nil targetQueue:queue];
  });

  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  it(@"should execute on the right context", ^{
    __block BOOL blockRun = NO;
    __block LTGLContext *blockRunContext;

    waitUntil(^(DoneCallback done) {
      [otherContext executeAsyncBlock:^{
        blockRun = YES;
        blockRunContext = [LTGLContext currentContext];
        done();
      }];
    });
    expect(blockRun).to.beTruthy();
    expect(blockRunContext).to.equal(otherContext);
  });

  it(@"should restore the original context after context switch", ^{
    __block BOOL blockRun = NO;
    waitUntil(^(DoneCallback done) {
      [otherContext executeAsyncBlock:^{
        blockRun = YES;
        done();
      }];
    });
    expect([LTGLContext currentContext]).to.equal(context);
    expect(blockRun).to.beTruthy();
  });
});

SpecEnd
