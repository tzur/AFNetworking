// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import <stack>

/// OpenGL default blend function.
LTGLContextBlendFuncArgs kLTGLContextBlendFuncDefault = {
  .sourceRGB = LTGLContextBlendFuncOne,
  .destinationRGB = LTGLContextBlendFuncZero,
  .sourceAlpha = LTGLContextBlendFuncOne,
  .destinationAlpha = LTGLContextBlendFuncZero
};

/// Blend function similar to Photoshop's "Normal" blend.
LTGLContextBlendFuncArgs kLTGLContextBlendFuncNormal = {
  .sourceRGB = LTGLContextBlendFuncOne,
  .destinationRGB = LTGLContextBlendFuncOneMinusSrcAlpha,
  .sourceAlpha = LTGLContextBlendFuncOneMinusDstAlpha,
  .destinationAlpha = LTGLContextBlendFuncOne
};

/// OpenGL default blend equation (Additive).
LTGLContextBlendEquationArgs kLTGLContextBlendEquationDefault = {
  .equationRGB = LTGLContextBlendEquationAdd,
  .equationAlpha = LTGLContextBlendEquationAdd
};

/// Thread-specific \c LTGLContext accessor key.
static NSString * const kCurrentContextKey = @"com.lightricks.LTKit.LTGLContext";

/// POD for holding all context values.
typedef struct {
  LTGLContextBlendFuncArgs blendFunc;
  LTGLContextBlendEquationArgs blendEquation;

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
  glGetIntegerv(GL_BLEND_SRC_RGB, (GLint *)&_blendFunc.sourceRGB);
  glGetIntegerv(GL_BLEND_DST_RGB, (GLint *)&_blendFunc.destinationRGB);
  glGetIntegerv(GL_BLEND_SRC_ALPHA, (GLint *)&_blendFunc.sourceAlpha);
  glGetIntegerv(GL_BLEND_DST_ALPHA, (GLint *)&_blendFunc.destinationAlpha);
}

- (void)fetchBlendEquationState {
  glGetIntegerv(GL_BLEND_EQUATION_RGB, (GLint *)&_blendEquation.equationRGB);
  glGetIntegerv(GL_BLEND_EQUATION_ALPHA, (GLint *)&_blendEquation.equationAlpha);
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
    .blendFunc = self.blendFunc,
    .blendEquation = self.blendEquation,
    .blendEnabled = self.blendEnabled,
    .faceCullingEnabled = self.faceCullingEnabled,
    .depthTestEnabled = self.depthTestEnabled,
    .scissorTestEnabled = self.scissorTestEnabled,
    .stencilTestEnabled = self.stencilTestEnabled,
    .ditheringEnabled = self.ditheringEnabled
  };
}

- (void)setCurrentStateFromValues:(LTGLContextValues)values {
  self.blendFunc = values.blendFunc;
  self.blendEquation = values.blendEquation;
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

- (void)setBlendFunc:(LTGLContextBlendFuncArgs)blendFunc {
  if (_blendFunc.sourceRGB == blendFunc.sourceRGB &&
      _blendFunc.sourceAlpha == blendFunc.sourceAlpha &&
      _blendFunc.destinationRGB == blendFunc.destinationRGB &&
      _blendFunc.destinationAlpha == blendFunc.destinationAlpha) {
    return;
  }
  _blendFunc = blendFunc;
  [self updateBlendFunc];
}

- (void)setBlendEquation:(LTGLContextBlendEquationArgs)blendEquation {
  if (_blendEquation.equationRGB == blendEquation.equationRGB &&
      _blendEquation.equationAlpha == blendEquation.equationAlpha) {
    return;
  }
  _blendEquation = blendEquation;
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
  glBlendFuncSeparate(_blendFunc.sourceRGB, _blendFunc.destinationRGB,
                      _blendFunc.sourceAlpha, _blendFunc.destinationAlpha);
}

- (void)updateBlendEquation {
  [self assertContextIsCurrentContext];
  glBlendEquationSeparate(_blendEquation.equationRGB, _blendEquation.equationAlpha);
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
