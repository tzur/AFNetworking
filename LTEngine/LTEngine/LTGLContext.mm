// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import <stack>

#import "LTFboPool.h"

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

  CGRect scissorBox;

  BOOL renderingToScreen;
  BOOL blendEnabled;
  BOOL faceCullingEnabled;
  BOOL depthTestEnabled;
  BOOL scissorTestEnabled;
  BOOL stencilTestEnabled;
  BOOL ditheringEnabled;
  BOOL clockwiseFrontFacingPolygons;

  GLint packAlignment;
  GLint unpackAlignment;
} LTGLContextValues;

@interface LTGLContext () {
  std::stack<LTGLContextValues> _contextStack;
}

/// Underlying \c EAGLContext.
@property (strong, nonatomic) EAGLContext *context;

/// Framebuffer pool associated with this context.
@property (strong, nonatomic) LTFboPool *fboPool;

/// Holds \c LTGLContextValues objects for each \c executeAndRestoreState: call. Note that this is
/// a stack since it's possible to have recursive calls to \c executeAndRestoreState:.
@property (readonly, nonatomic) std::stack<LTGLContextValues> &contextStack;

/// Set of \c NSString objects of the supported extensions of this context.
@property (readwrite, nonatomic) NSSet *supportedExtensions;

/// Maximal texture size that can be used on the device's GPU.
@property (readwrite, nonatomic) GLint maxTextureSize;

/// Maximal number of texture units that can be used on the device GPU.
@property (readwrite, nonatomic) GLint maxTextureUnits;

@end

@implementation LTGLContext

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithSharegroup:nil];
}

- (instancetype)initWithSharegroup:(EAGLSharegroup *)sharegroup {
  if (self = [super init]) {
    self.context = [self createEAGLContextWithSharegroup:sharegroup];
    self.fboPool = [[LTFboPool alloc] init];
  }
  return self;
}

- (instancetype)initWithSharegroup:(EAGLSharegroup *)sharegroup
                           version:(LTGLContextAPIVersion)version {
  if (self = [super init]) {
    self.context = [self createEAGLContextWithSharegroup:sharegroup version:version];
    if (!self.context) {
      return nil;
    }
    self.fboPool = [[LTFboPool alloc] init];
  }
  return self;
}

- (EAGLContext *)createEAGLContextWithSharegroup:(EAGLSharegroup *)sharegroup {
  EAGLContext *context = [self createEAGLContextWithSharegroup:sharegroup
                                                       version:LTGLContextAPIVersion3];
  if (!context) {
    context = [self createEAGLContextWithSharegroup:sharegroup
                                            version:LTGLContextAPIVersion2];
  }
  LTAssert(context, @"EAGLContext creation with sharegroup %@ failed", sharegroup);
  return context;
}

- (EAGLContext *)createEAGLContextWithSharegroup:(EAGLSharegroup *)sharegroup
                                         version:(LTGLContextAPIVersion)version {
  return [[EAGLContext alloc] initWithAPI:(EAGLRenderingAPI)version
                               sharegroup:sharegroup];
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

- (LTGLContextAPIVersion)version {
  switch (self.context.API) {
    case kEAGLRenderingAPIOpenGLES2:
      return LTGLContextAPIVersion2;
    case kEAGLRenderingAPIOpenGLES3:
      return LTGLContextAPIVersion3;
    default:
      LTAssert(NO, @"Unknwon API version being used: %lu", (unsigned long)self.context.API);
  }
}

#pragma mark -
#pragma mark Fetching state from OpenGL
#pragma mark -

- (void)fetchState {
  [self fetchBlendFuncState];
  [self fetchBlendEquationState];
  [self fetchScissorBoxState];
  [self fetchFlagsState];
  [self fetchFrontFaceState];
  [self fetchAlignmentState];
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

- (void)fetchScissorBoxState {
  GLint box[4];
  glGetIntegerv(GL_SCISSOR_BOX, box);
  self.scissorBox = CGRectMake(box[0], box[1], box[2], box[3]);
}

- (void)fetchFlagsState {
  _blendEnabled = glIsEnabled(GL_BLEND);
  _faceCullingEnabled = glIsEnabled(GL_CULL_FACE);
  _depthTestEnabled = glIsEnabled(GL_DEPTH_TEST);
  _scissorTestEnabled = glIsEnabled(GL_SCISSOR_TEST);
  _stencilTestEnabled = glIsEnabled(GL_STENCIL_TEST);
  _ditheringEnabled = glIsEnabled(GL_DITHER);
}

- (void)fetchFrontFaceState {
  GLint frontFace;
  glGetIntegerv(GL_FRONT_FACE, &frontFace);
  _clockwiseFrontFacingPolygons = (frontFace == GL_CW);
}

- (void)fetchAlignmentState {
  GLint packAlignment, unpackAlignment;
  glGetIntegerv(GL_PACK_ALIGNMENT, &packAlignment);
  glGetIntegerv(GL_UNPACK_ALIGNMENT, &unpackAlignment);
  _packAlignment = packAlignment;
  _unpackAlignment = unpackAlignment;
}

#pragma mark -
#pragma mark Storing and fetching internal state
#pragma mark -

- (LTGLContextValues)valuesForCurrentState {
  return {
    .blendFunc = self.blendFunc,
    .blendEquation = self.blendEquation,
    .scissorBox = self.scissorBox,
    .renderingToScreen = self.renderingToScreen,
    .blendEnabled = self.blendEnabled,
    .faceCullingEnabled = self.faceCullingEnabled,
    .depthTestEnabled = self.depthTestEnabled,
    .scissorTestEnabled = self.scissorTestEnabled,
    .stencilTestEnabled = self.stencilTestEnabled,
    .ditheringEnabled = self.ditheringEnabled,
    .clockwiseFrontFacingPolygons = self.clockwiseFrontFacingPolygons,
    .packAlignment = self.packAlignment,
    .unpackAlignment = self.unpackAlignment
  };
}

- (void)setCurrentStateFromValues:(LTGLContextValues)values {
  self.renderingToScreen = values.renderingToScreen;
  self.blendFunc = values.blendFunc;
  self.blendEquation = values.blendEquation;
  self.scissorBox = values.scissorBox;
  self.blendEnabled = values.blendEnabled;
  self.faceCullingEnabled = values.faceCullingEnabled;
  self.depthTestEnabled = values.depthTestEnabled;
  self.scissorTestEnabled = values.scissorTestEnabled;
  self.stencilTestEnabled = values.stencilTestEnabled;
  self.ditheringEnabled = values.ditheringEnabled;
  self.clockwiseFrontFacingPolygons = values.clockwiseFrontFacingPolygons;
  self.packAlignment = values.packAlignment;
  self.unpackAlignment = values.unpackAlignment;
}

#pragma mark -
#pragma mark Execution
#pragma mark -

- (void)executeAndPreserveState:(LTGLContextBlock)execute {
  LTParameterAssert(execute);
  [self assertContextIsCurrentContext];
  
  self.contextStack.emplace([self valuesForCurrentState]);
  execute(self);
  [self setCurrentStateFromValues:self.contextStack.top()];
  self.contextStack.pop();
}

- (void)executeForOpenGLES2:(LTVoidBlock)openGLES2 openGLES3:(LTVoidBlock)openGLES3 {
  LTParameterAssert(openGLES2);
  LTParameterAssert(openGLES3);

  switch (self.version) {
    case LTGLContextAPIVersion2:
      openGLES2();
      break;
    case LTGLContextAPIVersion3:
      openGLES3();
      break;
  }
}

- (void)clearWithColor:(LTVector4)color {
  LTVector4 previousColor;
  glGetFloatv(GL_COLOR_CLEAR_VALUE, previousColor.data());

  glClearColor(color.r(), color.g(), color.b(), color.a());
  glClear(GL_COLOR_BUFFER_BIT);
  glClearColor(previousColor.r(), previousColor.g(), previousColor.b(), previousColor.a());
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

- (void)setScissorBox:(CGRect)scissorBox {
  scissorBox = CGRoundRect(scissorBox);
  if (_scissorBox == scissorBox) {
    return;
  }
  _scissorBox = scissorBox;
  [self updateScissorBox];
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

- (void)setClockwiseFrontFacingPolygons:(BOOL)clockwiseFrontFacingPolygons {
  if (_clockwiseFrontFacingPolygons == clockwiseFrontFacingPolygons) {
    return;
  }
  _clockwiseFrontFacingPolygons = clockwiseFrontFacingPolygons;
  [self updateFrontFace];
}

- (void)setPackAlignment:(GLint)packAlignment {
  if (_packAlignment == packAlignment) {
    return;
  }
  [self verifyAlignment:packAlignment];
  _packAlignment = packAlignment;
  glPixelStorei(GL_PACK_ALIGNMENT, packAlignment);
}

- (void)setUnpackAlignment:(GLint)unpackAlignment {
  if (_unpackAlignment == unpackAlignment) {
    return;
  }
  [self verifyAlignment:unpackAlignment];
  _unpackAlignment = unpackAlignment;
  glPixelStorei(GL_UNPACK_ALIGNMENT, unpackAlignment);
}

- (void)verifyAlignment:(GLint)alignment {
  static NSArray const *kValidAlignments = @[@1, @2, @4, @8];
  LTParameterAssert([kValidAlignments containsObject:@(alignment)],
                    @"Given alignment '%d' is not one of the allowed values", alignment);
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

- (void)updateScissorBox {
  [self assertContextIsCurrentContext];
  glScissor(self.scissorBox.origin.x, self.scissorBox.origin.y,
            self.scissorBox.size.width, self.scissorBox.size.height);
}

- (void)updateCapability:(GLenum)capability withValue:(BOOL)value {
  [self assertContextIsCurrentContext];
  if (value) {
    glEnable(capability);
  } else {
    glDisable(capability);
  }
}

- (void)updateFrontFace {
  [self assertContextIsCurrentContext];
  glFrontFace(self.clockwiseFrontFacingPolygons ? GL_CW : GL_CCW);
}

- (void)assertContextIsCurrentContext {
  LTAssert([self isSetAsCurrentContext],
           @"Trying to modify context while not set as current context");
}


#pragma mark -
#pragma mark Capabilities
#pragma mark -

- (NSSet *)supportedExtensions {
  if (!_supportedExtensions) {
    NSString *extensions = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS)
                                              encoding:NSASCIIStringEncoding];
    NSString *trimmed = [extensions
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    _supportedExtensions = [NSSet setWithArray:[trimmed componentsSeparatedByString:@" "]];
  }
  return _supportedExtensions;
}

- (GLint)maxTextureSize {
  if (!_maxTextureSize) {
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &_maxTextureSize);
  }
  return _maxTextureSize;
}

- (GLint)maxTextureUnits {
  if (!_maxTextureUnits) {
    glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &_maxTextureUnits);
  }
  return _maxTextureUnits;
}

- (BOOL)canRenderToHalfFloatTextures {
  return [self.supportedExtensions containsObject:@"GL_EXT_color_buffer_half_float"];
}

- (BOOL)canRenderToFloatTextures {
  return [self.supportedExtensions containsObject:@"GL_EXT_color_buffer_float"];
}

- (BOOL)supportsRGTextures {
  return self.version == LTGLContextAPIVersion3 ||
      [self.supportedExtensions containsObject:@"GL_EXT_texture_rg"];
}

@end
