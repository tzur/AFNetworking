// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

SpecBegin(LTGLContext)

context(@"initialization", ^{
  it(@"should initialize with no context", ^{
    LTGLContext *context = [[LTGLContext alloc] init];

    expect(context.context).toNot.beNil();
  });

  it(@"should initialize with a given context", ^{
    EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    LTGLContext *context = [[LTGLContext alloc] initWithContext:eaglContext];

    expect(context.context).to.equal(eaglContext);
  });

  it(@"should set context as current context", ^{
    LTGLContext *context = [[LTGLContext alloc] init];

    expect(context.context).to.equal([EAGLContext currentContext]);
  });
});

sharedExamplesFor(@"having default opengl values", ^(NSDictionary *data) {
  LTGLContext *context = data[@"context"];

  expect(context.blendFuncSourceRGB).to.equal(GL_ONE);
  expect(context.blendFuncDestinationRGB).to.equal(GL_ZERO);
  expect(context.blendFuncSourceAlpha).to.equal(GL_ONE);
  expect(context.blendFuncDestinationAlpha).to.equal(GL_ZERO);

  expect(context.blendEquationRGB).to.equal(GL_FUNC_ADD);
  expect(context.blendEquationAlpha).to.equal(GL_FUNC_ADD);

  expect(context.blendEnabled).to.beFalsy();
  expect(context.faceCullingEnabled).to.beFalsy();
  expect(context.depthTestEnabled).to.beFalsy();
  expect(context.scissorTestEnabled).to.beFalsy();
  expect(context.stencilTestEnabled).to.beFalsy();
  expect(context.ditheringEnabled).to.beTruthy();
});

context(@"context values", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
  });

  it(@"should have default opengl values", ^{
    expect(context.blendFuncSourceRGB).to.equal(GL_ONE);
    expect(context.blendFuncDestinationRGB).to.equal(GL_ZERO);
    expect(context.blendFuncSourceAlpha).to.equal(GL_ONE);
    expect(context.blendFuncDestinationAlpha).to.equal(GL_ZERO);

    expect(context.blendEquationRGB).to.equal(GL_FUNC_ADD);
    expect(context.blendEquationAlpha).to.equal(GL_FUNC_ADD);

    expect(context.blendEnabled).to.beFalsy();
    expect(context.faceCullingEnabled).to.beFalsy();
    expect(context.depthTestEnabled).to.beFalsy();
    expect(context.scissorTestEnabled).to.beFalsy();
    expect(context.stencilTestEnabled).to.beFalsy();
    expect(context.ditheringEnabled).to.beTruthy();
  });

  itShouldBehaveLike(@"having default opengl values", ^{
    return @{@"context": context};
  });

  it(@"should set blend functions", ^{
    context.blendFuncSourceRGB = LTGLStateBlendFuncOneMinusDstAlpha;
    context.blendFuncDestinationRGB = LTGLStateBlendFuncOneMinusDstAlpha;
    context.blendFuncSourceAlpha = LTGLStateBlendFuncOneMinusDstAlpha;
    context.blendFuncDestinationAlpha = LTGLStateBlendFuncOneMinusDstAlpha;

    expect(context.blendFuncSourceRGB).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
    expect(context.blendFuncDestinationRGB).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
    expect(context.blendFuncSourceAlpha).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
    expect(context.blendFuncDestinationAlpha).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);

    GLint blendFuncSourceRGB, blendFuncDestinationRGB;
    GLint blendFuncSourceAlpha, blendFuncDestinationAlpha;

    glGetIntegerv(GL_BLEND_SRC_RGB, &blendFuncSourceRGB);
    glGetIntegerv(GL_BLEND_DST_RGB, &blendFuncDestinationRGB);
    glGetIntegerv(GL_BLEND_SRC_ALPHA, &blendFuncSourceAlpha);
    glGetIntegerv(GL_BLEND_DST_ALPHA, &blendFuncDestinationAlpha);

    expect(blendFuncSourceRGB).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
    expect(blendFuncDestinationRGB).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
    expect(blendFuncSourceAlpha).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
    expect(blendFuncDestinationAlpha).to.equal(LTGLStateBlendFuncOneMinusDstAlpha);
  });

  it(@"should set blend equations", ^{
    context.blendEquationRGB = LTGLStateBlendEquationReverseSubtract;
    context.blendEquationAlpha = LTGLStateBlendEquationReverseSubtract;

    GLint blendEquationRGB, blendEquationAlpha;

    glGetIntegerv(GL_BLEND_EQUATION_RGB, &blendEquationRGB);
    glGetIntegerv(GL_BLEND_EQUATION_ALPHA, &blendEquationAlpha);

    expect(blendEquationRGB).to.equal(LTGLStateBlendEquationReverseSubtract);
    expect(blendEquationAlpha).to.equal(LTGLStateBlendEquationReverseSubtract);
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
});

context(@"execution", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
  });

  // State preserving.
  itShouldBehaveLike(@"having default opengl values", ^{
    [context executeAndPreserveState:^{
      context.blendFuncSourceRGB = LTGLStateBlendFuncOneMinusDstAlpha;
      context.blendFuncDestinationRGB = LTGLStateBlendFuncOneMinusDstAlpha;
      context.blendFuncSourceAlpha = LTGLStateBlendFuncOneMinusDstAlpha;
      context.blendFuncDestinationAlpha = LTGLStateBlendFuncOneMinusDstAlpha;

      context.blendEquationRGB = LTGLStateBlendEquationReverseSubtract;
      context.blendEquationAlpha = LTGLStateBlendEquationReverseSubtract;

      context.blendEnabled = !context.blendEnabled;
      context.faceCullingEnabled = !context.faceCullingEnabled;
      context.depthTestEnabled = !context.depthTestEnabled;
      context.scissorTestEnabled = !context.scissorTestEnabled;
      context.stencilTestEnabled = !context.stencilTestEnabled;
      context.ditheringEnabled = !context.ditheringEnabled;
    }];

    return @{@"context": context};
  });

  it(@"should support recursive execution", ^{
    [context executeAndPreserveState:^{
      context.blendEnabled = YES;

      [context executeAndPreserveState:^{
        context.blendEnabled = NO;
        expect(context.blendEnabled).to.beFalsy();
      }];

      expect(context.blendEnabled).to.beTruthy();
    }];

    expect(context.blendEnabled).to.beFalsy();
  });
});

SpecEnd
