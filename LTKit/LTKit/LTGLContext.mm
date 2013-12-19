// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import <stack>

typedef struct {
  LTGLStateBlendFunc blendFuncSourceRGB;
  LTGLStateBlendFunc blendFuncDestinationRGB;
  LTGLStateBlendFunc blendFuncSourceAlpha;
  LTGLStateBlendFunc blendFuncDestinationAlpha;

  LTGLStateBlendEquation blendEquationRGB;
  LTGLStateBlendEquation blendEquationAlpha;

  BOOL blendEnabled;
  BOOL faceCullingEnabled;
  BOOL depthTestEnabled;
  BOOL scissorTestEnabled;
  BOOL stencilTestEnabled;
  BOOL ditheringEnabled;
} LTGLContextValues;

@interface LTGLContext () {
  std::stack<LTGLContextValues> _contextStack;
}

/// Underlying \c EAGLContext.
@property (strong, nonatomic) EAGLContext *context;

/// Holds \c LTGLContextValues objects for each \c executeAndRestoreState: call. Note that this is
/// a stack since it's possible to have recursive calls to \c executeAndRestoreState:.
@property (readonly, nonatomic) std::stack<LTGLContextValues> &contextStack;

@end

@implementation LTGLContext

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  LTAssert(context, @"EAGLContext creation failed");
  return [self initWithContext:context];
}

- (instancetype)initWithContext:(EAGLContext *)context {
  if (self = [super init]) {
    self.context = context;
    [self setAsCurrentContext];
    [self fetchState];
  }
  return self;
}

#pragma mark -
#pragma mark Fetching state from OpenGL
#pragma mark -

- (void)fetchState {
  [self fetchBlendFuncState];
  [self fetchBlendEquationState];
  [self fetchFlagsState];
  LTGLCheckDbg(@"Failed retrieving context state");
}

- (void)fetchBlendFuncState {
  glGetIntegerv(GL_BLEND_SRC_RGB, (GLint *)&_blendFuncSourceRGB);
  glGetIntegerv(GL_BLEND_DST_RGB, (GLint *)&_blendFuncDestinationRGB);
  glGetIntegerv(GL_BLEND_SRC_ALPHA, (GLint *)&_blendFuncSourceAlpha);
  glGetIntegerv(GL_BLEND_DST_ALPHA, (GLint *)&_blendFuncDestinationAlpha);
}

- (void)fetchBlendEquationState {
  glGetIntegerv(GL_BLEND_EQUATION_RGB, (GLint *)&_blendEquationRGB);
  glGetIntegerv(GL_BLEND_EQUATION_ALPHA, (GLint *)&_blendEquationAlpha);
}

- (void)fetchFlagsState {
  self.blendEnabled = glIsEnabled(GL_BLEND);
  self.faceCullingEnabled = glIsEnabled(GL_CULL_FACE);
  self.depthTestEnabled = glIsEnabled(GL_DEPTH_TEST);
  self.scissorTestEnabled = glIsEnabled(GL_SCISSOR_TEST);
  self.stencilTestEnabled = glIsEnabled(GL_STENCIL_TEST);
  self.ditheringEnabled = glIsEnabled(GL_DITHER);
}

#pragma mark -
#pragma mark Storing and fetching internal state
#pragma mark -

- (LTGLContextValues)valuesForCurrentState {
  return {
    .blendFuncSourceRGB = self.blendFuncSourceRGB,
    .blendFuncDestinationRGB = self.blendFuncDestinationRGB,
    .blendFuncSourceAlpha = self.blendFuncSourceAlpha,
    .blendFuncDestinationAlpha = self.blendFuncDestinationAlpha,

    .blendEquationRGB = self.blendEquationRGB,
    .blendEquationAlpha =self.blendEquationAlpha,

    .blendEnabled = self.blendEnabled,
    .faceCullingEnabled = self.faceCullingEnabled,
    .depthTestEnabled = self.depthTestEnabled,
    .scissorTestEnabled = self.scissorTestEnabled,
    .stencilTestEnabled = self.stencilTestEnabled,
    .ditheringEnabled = self.ditheringEnabled
  };
}

- (void)setCurrentStateFromValues:(LTGLContextValues)values {
  self.blendFuncSourceRGB = values.blendFuncSourceRGB;
  self.blendFuncDestinationRGB = values.blendFuncDestinationRGB;
  self.blendFuncSourceAlpha = values.blendFuncSourceAlpha;
  self.blendFuncDestinationAlpha = values.blendFuncDestinationAlpha;

  self.blendEquationRGB = values.blendEquationRGB;
  self.blendEquationAlpha = values.blendEquationAlpha;

  self.blendEnabled = values.blendEnabled;
  self.faceCullingEnabled = values.faceCullingEnabled;
  self.depthTestEnabled = values.depthTestEnabled;
  self.scissorTestEnabled = values.scissorTestEnabled;
  self.stencilTestEnabled = values.stencilTestEnabled;
  self.ditheringEnabled = values.ditheringEnabled;
}

#pragma mark -
#pragma mark Execution
#pragma mark -

- (void)executeAndPreserveState:(LTVoidBlock)execute {
  if (!execute) {
    return;
  }

  self.contextStack.emplace([self valuesForCurrentState]);
  execute();
  [self setCurrentStateFromValues:self.contextStack.top()];
  self.contextStack.pop();
}

#pragma mark -
#pragma mark EAGLContext
#pragma mark -

- (void)setAsCurrentContext {
  [EAGLContext setCurrentContext:self.context];
}

#pragma mark -
#pragma mark Context properties
#pragma mark -

- (void)setBlendFuncSourceRGB:(LTGLStateBlendFunc)blendFuncSourceRGB {
  if (_blendFuncSourceRGB == blendFuncSourceRGB) {
    return;
  }
  _blendFuncSourceRGB = blendFuncSourceRGB;
  [self updateBlendFunc];
}

- (void)setBlendFuncDestinationRGB:(LTGLStateBlendFunc)blendFuncDestinationRGB {
  if (_blendFuncDestinationRGB == blendFuncDestinationRGB) {
    return;
  }
  _blendFuncDestinationRGB = blendFuncDestinationRGB;
  [self updateBlendFunc];
}

- (void)setBlendFuncSourceAlpha:(LTGLStateBlendFunc)blendFuncSourceAlpha {
  if (_blendFuncSourceAlpha == blendFuncSourceAlpha) {
    return;
  }
  _blendFuncSourceAlpha = blendFuncSourceAlpha;
  [self updateBlendFunc];
}

- (void)setBlendFuncDestinationAlpha:(LTGLStateBlendFunc)blendFuncDestinationAlpha {
  if (_blendFuncDestinationAlpha == blendFuncDestinationAlpha) {
    return;
  }
  _blendFuncDestinationAlpha = blendFuncDestinationAlpha;
  [self updateBlendFunc];
}

- (void)setBlendEquationRGB:(LTGLStateBlendEquation)blendEquationRGB {
  if (_blendEquationRGB == blendEquationRGB) {
    return;
  }
  _blendEquationRGB = blendEquationRGB;
  [self updateBlendEquation];
}

- (void)setBlendEquationAlpha:(LTGLStateBlendEquation)blendEquationAlpha {
  if (_blendEquationAlpha == blendEquationAlpha) {
    return;
  }
  _blendEquationAlpha = blendEquationAlpha;
  [self updateBlendEquation];
}

- (void)setBlendEnabled:(BOOL)blendEnabled {
  if (_blendEnabled == blendEnabled) {
    return;
  }
  _blendEnabled = blendEnabled;
  [self updateCapability:GL_BLEND withValue:blendEnabled];
}

- (void)setFaceCullingEnabled:(BOOL)faceCullingEnabled {
  if (_faceCullingEnabled == faceCullingEnabled) {
    return;
  }
  _faceCullingEnabled = faceCullingEnabled;
  [self updateCapability:GL_CULL_FACE withValue:faceCullingEnabled];
}

- (void)setDepthTestEnabled:(BOOL)depthTestEnabled {
  if (_depthTestEnabled == depthTestEnabled) {
    return;
  }
  _depthTestEnabled = depthTestEnabled;
  [self updateCapability:GL_DEPTH_TEST withValue:depthTestEnabled];
}

- (void)setScissorTestEnabled:(BOOL)scissorTestEnabled {
  if (_scissorTestEnabled == scissorTestEnabled) {
    return;
  }
  _scissorTestEnabled = scissorTestEnabled;
  [self updateCapability:GL_SCISSOR_TEST withValue:scissorTestEnabled];
}

- (void)setStencilTestEnabled:(BOOL)stencilTestEnabled {
  if (_stencilTestEnabled == stencilTestEnabled) {
    return;
  }
  _stencilTestEnabled = stencilTestEnabled;
  [self updateCapability:GL_STENCIL_TEST withValue:stencilTestEnabled];
}

- (void)setDitheringEnabled:(BOOL)ditheringEnabled {
  if (_ditheringEnabled == ditheringEnabled) {
    return;
  }
  _ditheringEnabled = ditheringEnabled;
  [self updateCapability:GL_DITHER withValue:ditheringEnabled];
}

- (void)updateBlendFunc {
  glBlendFuncSeparate(self.blendFuncSourceRGB, self.blendFuncDestinationRGB,
                      self.blendFuncSourceAlpha, self.blendFuncDestinationAlpha);
}

- (void)updateBlendEquation {
  glBlendEquationSeparate(self.blendEquationRGB, self.blendEquationAlpha);
}

- (void)updateCapability:(GLenum)capability withValue:(BOOL)value {
  if (value) {
    glEnable(capability);
  } else {
    glDisable(capability);
  }
}

@end
