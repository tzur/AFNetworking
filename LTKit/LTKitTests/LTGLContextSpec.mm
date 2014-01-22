// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTGLTexture.h"
#import "LTTestUtils.h"

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
    expect(context.blendEnabled).to.beFalsy();
    expect(context.faceCullingEnabled).to.beFalsy();
    expect(context.depthTestEnabled).to.beFalsy();
    expect(context.scissorTestEnabled).to.beFalsy();
    expect(context.stencilTestEnabled).to.beFalsy();
    expect(context.ditheringEnabled).to.beTruthy();
    expect(context.clockwiseFrontFacingPolygons).to.beFalsy();
  });
});

context(@"initialization", ^{
  it(@"should initialize with no context", ^{
    LTGLContext *context = [[LTGLContext alloc] init];

    expect(context.context).toNot.beNil();
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

    expect([LTGLContext currentContext]).to.beNil;
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
      [context executeAndPreserveState:^{
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
    [context executeAndPreserveState:^{
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
      
      context.blendEnabled = !context.blendEnabled;
      context.faceCullingEnabled = !context.faceCullingEnabled;
      context.depthTestEnabled = !context.depthTestEnabled;
      context.scissorTestEnabled = !context.scissorTestEnabled;
      context.stencilTestEnabled = !context.stencilTestEnabled;
      context.ditheringEnabled = !context.ditheringEnabled;
      context.clockwiseFrontFacingPolygons = !context.clockwiseFrontFacingPolygons;
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
  
  it(@"should clear the color buffers", ^{
    cv::Mat4b mat(10, 10);
    cv::Vec4b red(255, 0, 0, 255);
    cv::Vec4b blue(0, 0, 255, 255);
    mat = red;
    LTTexture *texture = [[LTGLTexture alloc] initWithImage:mat];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo bindAndDraw:^{
      [[LTGLContext currentContext] clearWithColor:GLKVector4FromVec4b(blue)];
    }];
    
    cv::Mat4b expected(mat.rows, mat.cols);
    expected = blue;
    expect(LTCompareMat(expected, [texture image])).to.beTruthy();
  });
  
  it(@"should clear the color buffers leaving the clearColor unchanged", ^{
    const GLKVector4 color1 = GLKVector4Make(1, 0, 0, 1);
    const GLKVector4 color2 = GLKVector4Make(0, 1, 0, 1);
    GLKVector4 clearColor;
    glClearColor(color1.r, color1.g, color1.b, color1.a);
    [[LTGLContext currentContext] clearWithColor:color2];
    glGetFloatv(GL_COLOR_CLEAR_VALUE, clearColor.v);
    expect(clearColor).to.equal(color1);
  });
});

SpecEnd
