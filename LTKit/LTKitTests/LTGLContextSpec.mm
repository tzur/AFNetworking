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
  });

  it(@"should initialize correctly with sharegroup", ^{
    LTGLContext *sharedContext = [[LTGLContext alloc]
                                  initWithSharegroup:context.context.sharegroup];
    expect(sharedContext.context).toNot.beNil();
    expect(sharedContext.context.sharegroup).to.equal(sharedContext.context.sharegroup);
    expect(sharedContext.fboPool).toNot.beNil();
  });

  it(@"should initialize with nil sharegroup", ^{
    LTGLContext *contextWithNilSharegrop = [[LTGLContext alloc] initWithSharegroup:nil];
    expect(contextWithNilSharegrop.context).toNot.beNil();
  });

  it(@"should initialize with API version 2", ^{
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil
                                                           version:LTGLContextAPIVersion2];
    expect(context.version).to.equal(LTGLContextAPIVersion2);
    expect(context.context.API).to.equal(kEAGLRenderingAPIOpenGLES2);
  });

  it(@"should initialize with API version 3", ^{
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil
                                                           version:LTGLContextAPIVersion3];
    expect(context.version).to.equal(LTGLContextAPIVersion3);
    expect(context.context.API).to.equal(kEAGLRenderingAPIOpenGLES3);
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
    cv::Mat4b mat(10, 10);
    cv::Vec4b red(255, 0, 0, 255);
    const LTVector4 kBlue(0, 0, 1, 1);
    mat = red;
    LTTexture *texture = [[LTGLTexture alloc] initWithImage:mat];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
    [fbo bindAndDraw:^{
      [[LTGLContext currentContext] clearWithColor:kBlue];
    }];

    LTVector4 charBlue(kBlue * 255);
    cv::Mat4b expected(mat.rows, mat.cols,
                       cv::Vec4b(charBlue.r(), charBlue.g(), charBlue.b(), charBlue.a()));
    expect(LTFuzzyCompareMat(expected, [texture image])).to.beTruthy();
  });
  
  it(@"should clear the color buffers leaving the clearColor unchanged", ^{
    const LTVector4 kColor1 = LTVector4(1, 0, 0, 1);
    const LTVector4 kColor2 = LTVector4(0, 1, 0, 1);
    LTVector4 clearColor;
    glClearColor(kColor1.r(), kColor1.g(), kColor1.b(), kColor1.a());
    [[LTGLContext currentContext] clearWithColor:kColor2];
    glGetFloatv(GL_COLOR_CLEAR_VALUE, clearColor.data());
    expect(clearColor).to.equal(kColor1);
  });
});

context(@"OpenGL ES version execution", ^{
  it(@"should execute version 2 block if version 2 is set", ^{
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil
                                                           version:LTGLContextAPIVersion2];

    __block BOOL version2 = NO;
    __block BOOL version3 = NO;
    [context executeForOpenGLES2:^{
      version2 = YES;
    } openGLES3:^{
      version3 = YES;
    }];

    expect(version2).to.beTruthy();
    expect(version3).to.beFalsy();
  });

  it(@"should execute version 2 block if version 3 is set", ^{
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil
                                                           version:LTGLContextAPIVersion3];

    __block BOOL version2 = NO;
    __block BOOL version3 = NO;
    [context executeForOpenGLES2:^{
      version2 = YES;
    } openGLES3:^{
      version3 = YES;
    }];

    expect(version2).to.beFalsy();
    expect(version3).to.beTruthy();
  });
});

SpecEnd
