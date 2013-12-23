// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import <stack>

/// Thread-specific \c LTGLContext accessor key.
static NSString * const kCurrentContextKey = @"com.lightricks.LTKit.LTGLContext";

/// POD for holding all context values.
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
  if (self = [super init]) {
    self.context = [self createEAGLContext];
  }
  return self;
}

- (EAGLContext *)createEAGLContext {
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  LTAssert(context, @"EAGLContext creation failed");
  return context;
}

#pragma mark -
#pragma mark Current context
#pragma mark -

+ (LTGLContext *)currentContext {
  return [[NSThread currentThread] threadDictionary][kCurrentContextKey];
}

+ (void)setCurrentContext:(LTGLContext *)context {
  if (context) {
    [[self class] setContextForCurrentThread:context];
  } else {
    [[self class] clearContextFromCurrentThread];
  }
}

+ (void)setContextForCurrentThread:(LTGLContext *)context {
  [[NSThread currentThread] threadDictionary][kCurrentContextKey] = context;

  BOOL contextSet = [EAGLContext setCurrentContext:context.context];
  LTAssert(contextSet, @"Failed to set context as current context");

  [context fetchState];
}

+ (void)clearContextFromCurrentThread {
  [[[NSThread currentThread] threadDictionary] removeObjectForKey:kCurrentContextKey];
  [EAGLContext setCurrentContext:nil];
}

- (BOOL)isSetAsCurrentContext {
  return [[self class] currentContext] == self;
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
  _blendEnabled = glIsEnabled(GL_BLEND);
  _faceCullingEnabled = glIsEnabled(GL_CULL_FACE);
  _depthTestEnabled = glIsEnabled(GL_DEPTH_TEST);
  _scissorTestEnabled = glIsEnabled(GL_SCISSOR_TEST);
  _stencilTestEnabled = glIsEnabled(GL_STENCIL_TEST);
  _ditheringEnabled = glIsEnabled(GL_DITHER);
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
    .blendEquationAlpha = self.blendEquationAlpha,

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
  LTParameterAssert(execute);
  [self assertContextIsCurrentContext];

  self.contextStack.emplace([self valuesForCurrentState]);
  execute();
  [self setCurrentStateFromValues:self.contextStack.top()];
  self.contextStack.pop();
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
  [self assertContextIsCurrentContext];
  glBlendFuncSeparate(self.blendFuncSourceRGB, self.blendFuncDestinationRGB,
                      self.blendFuncSourceAlpha, self.blendFuncDestinationAlpha);
}

- (void)updateBlendEquation {
  [self assertContextIsCurrentContext];
  glBlendEquationSeparate(self.blendEquationRGB, self.blendEquationAlpha);
}

- (void)updateCapability:(GLenum)capability withValue:(BOOL)value {
  [self assertContextIsCurrentContext];
  if (value) {
    glEnable(capability);
  } else {
    glDisable(capability);
  }
}

- (void)assertContextIsCurrentContext {
  LTAssert([self isSetAsCurrentContext],
           @"Trying to modify context while not set as current context");
}

@end
