// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

#import <stack>

#import "LTFboPool.h"
#import "LTGPUResource.h"
#import "LTProgramPool.h"

NS_ASSUME_NONNULL_BEGIN

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

  LTGLDepthRange depthRange;
  BOOL depthMask;
  LTGLFunction depthFunc;
} LTGLContextValues;

@interface LTGLContext () {
  std::stack<LTGLContextValues> _contextStack;
}

/// Holds \c LTGLContextValues objects for each \c executeAndRestoreState: call. Note that this is
/// a stack since it's possible to have recursive calls to \c executeAndRestoreState:.
@property (readonly, nonatomic) std::stack<LTGLContextValues> &contextStack;

/// Set of \c NSString objects of the supported extensions of this context.
@property (readwrite, nonatomic) NSSet *supportedExtensions;

/// Maximal texture size that can be used on the device's GPU.
@property (readwrite, nonatomic) GLint maxTextureSize;

/// Maximal number of texture units that can be used in the vertex and fragment shader combined on
/// the device GPU. A texture used both in the vertex and fragment shader is counted as 2 textures.
@property (readwrite, nonatomic) GLint maxTextureUnits;

/// Maximal number of texture units that can be used in the fragment shader on the device GPU.
@property (readwrite, nonatomic) GLint maxFragmentTextureUnits;

/// Maximum number of individual 4-vectors of floating-point, integer, or boolean values that can be
/// held in uniform variable storage by the device GPU for a vertex shader.
@property (readwrite, nonatomic) GLint maxNumberOfVertexUniforms;

/// Maximum number of individual 4-vectors of floating-point, integer, or boolean values that can be
/// held in uniform variable storage by the device GPU for a fragment shader.
@property (readwrite, nonatomic) GLint maxNumberOfFragmentUniforms;

/// Maximum number of color attachments that can be used on the device's GPU.
@property (readwrite, nonatomic) GLint maxNumberOfColorAttachmentPoints;

/// Maps between resource's name, prepended with resources's \c Class, and its associated
/// \c LTGPUResource, which is held weakly.
///
/// @note key construction guarantees unique keys for two resources of different type with same
/// \c name.
///
/// @note table's entry management is being done manually, since it has many subtleties as explaned
/// http://cocoamine.net/blog/2013/12/13/nsmaptable-and-zeroing-weak-references/
@property (strong, nonatomic) NSMapTable<NSString *, id<LTGPUResource>> *nameToResource;

/// Serial queue which feeds the \c targetQueue with tasks executed by this context.
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation LTGLContext

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithSharegroup:nil];
}

- (instancetype)initWithSharegroup:(nullable EAGLSharegroup *)sharegroup {
  return [self initWithSharegroup:sharegroup versions:@[@(LTGLVersion3), @(LTGLVersion2)]
                      targetQueue:dispatch_get_main_queue()];
}

- (instancetype)initWithSharegroup:(nullable EAGLSharegroup *)sharegroup
                       targetQueue:(dispatch_queue_t)targetQueue {
  return [self initWithSharegroup:sharegroup versions:@[@(LTGLVersion3), @(LTGLVersion2)]
                      targetQueue:targetQueue];
}

- (instancetype)initWithSharegroup:(nullable EAGLSharegroup *)sharegroup
                           version:(LTGLVersion)version {
  return [self initWithSharegroup:sharegroup versions:@[@(version)]
                      targetQueue:dispatch_get_main_queue()];
}

- (instancetype)initWithSharegroup:(nullable EAGLSharegroup *)sharegroup
                          versions:(NSArray<NSNumber *> *)versions
                       targetQueue:(dispatch_queue_t)targetQueue {
  if (self = [super init]) {
    for (NSNumber *version in versions) {
      EAGLRenderingAPI api = (EAGLRenderingAPI)version.unsignedIntegerValue;
      _context = [[EAGLContext alloc] initWithAPI:api sharegroup:sharegroup];
      if (_context) {
        break;
      }
    }
    LTAssert(self.context, @"EAGLContext creation with sharegroup %@ failed", sharegroup);

    _fboPool = [[LTFboPool alloc] init];
    _programPool = [[LTProgramPool alloc] init];
    _nameToResource = [NSMapTable strongToWeakObjectsMapTable];
    [self setupQueuesWithTargetQueue:targetQueue];
  }
  return self;
}

- (void)setupQueuesWithTargetQueue:(dispatch_queue_t)targetQueue {
  _targetQueue = targetQueue;
  _serialQueue = dispatch_queue_create("com.lightricks.LTEngine.LTGLContext-serialQueue",
                                       DISPATCH_QUEUE_SERIAL);
  // Set specific key-value for _targetQueue to allow querying whether running on it.
  dispatch_queue_set_specific(_targetQueue, (__bridge void *)self, (__bridge void *)self, NULL);
  dispatch_set_target_queue(_serialQueue, _targetQueue);
}

- (void)dealloc {
  EAGLContext *currentContext = [EAGLContext currentContext];
  [EAGLContext setCurrentContext:self.context];
  [self.programPool flush];
  [EAGLContext setCurrentContext:currentContext];
}

#pragma mark -
#pragma mark Resource management
#pragma mark -

- (void)addResource:(id<LTGPUResource>)resource {
  [self.nameToResource setObject:resource forKey:[self keyFromResource:resource]];
}

- (void)removeResource:(id<LTGPUResource>)resource {
  [self.nameToResource removeObjectForKey:[self keyFromResource:resource]];
}

- (NSArray<id<LTGPUResource>> *)resources {
  auto resources = [NSMutableArray arrayWithCapacity:self.nameToResource.count];
  for (NSString *key in self.nameToResource) {
    [resources addObject:[self.nameToResource objectForKey:key]];
  }
  return [resources copy];
}

- (NSString *)keyFromResource:(id<LTGPUResource>)resource {
  return [NSString stringWithFormat:@"%@%d", [resource class], resource.name];
}

#pragma mark -
#pragma mark Current context
#pragma mark -

+ (nullable LTGLContext *)currentContext {
  return [[NSThread currentThread] threadDictionary][kCurrentContextKey];
}

+ (void)setCurrentContext:(nullable LTGLContext *)context {
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

- (LTGLVersion)version {
  switch (self.context.API) {
    case kEAGLRenderingAPIOpenGLES2:
      return LTGLVersion2;
    case kEAGLRenderingAPIOpenGLES3:
      return LTGLVersion3;
    default:
      LTAssert(NO, @"Unknown API version being used: %lu", (unsigned long)self.context.API);
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
  [self fetchDepthState];
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

- (void)fetchDepthState {
  GLboolean enabled;
  glGetBooleanv(GL_DEPTH_WRITEMASK, &enabled);
  _depthMask = enabled;

  GLfloat mapping[2];
  glGetFloatv(GL_DEPTH_RANGE, mapping);
  _depthRange = {.nearPlane = mapping[0], .farPlane = mapping[1]};

  glGetIntegerv(GL_DEPTH_FUNC, (GLint *)&_depthFunc);
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
    .unpackAlignment = self.unpackAlignment,
    .depthRange = self.depthRange,
    .depthMask = self.depthMask,
    .depthFunc = self.depthFunc
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
  self.depthRange = values.depthRange;
  self.depthMask = values.depthMask;
  self.depthFunc = values.depthFunc;
}

#pragma mark -
#pragma mark Execution
#pragma mark -

- (void)executeAndPreserveState:(NS_NOESCAPE LTGLContextBlock)execute {
  LTParameterAssert(execute);
  [self assertContextIsCurrentContext];

  self.contextStack.emplace([self valuesForCurrentState]);
  execute(self);
  [self setCurrentStateFromValues:self.contextStack.top()];
  self.contextStack.pop();
}

- (void)executeForOpenGLES2:(NS_NOESCAPE LTVoidBlock)openGLES2
                  openGLES3:(NS_NOESCAPE LTVoidBlock)openGLES3 {
  LTParameterAssert(openGLES2);
  LTParameterAssert(openGLES3);

  switch (self.version) {
    case LTGLVersion2:
      openGLES2();
      break;
    case LTGLVersion3:
      openGLES3();
      break;
  }
}

- (void)executeAsyncBlock:(LTVoidBlock)block {
  if ([self isOnContextQueue]) {
    [self switchContextIfNeededAndExecuteAsyncBlock:block];
  } else {
    dispatch_async(self.serialQueue, ^{
      [self switchContextIfNeededAndExecuteAsyncBlock:block];
    });
  }
}

- (BOOL)isOnContextQueue {
  return dispatch_get_specific((__bridge void *)self) == (__bridge void * _Nullable)self;
}

- (void)switchContextIfNeededAndExecuteAsyncBlock:(LTVoidBlock)block {
  LTGLContext * _Nullable previousContext = nil;
  BOOL restorePrevious = NO;
  if (![self isSetAsCurrentContext]) {
    previousContext = [LTGLContext currentContext];
    [LTGLContext setCurrentContext:self];
    restorePrevious = YES;
  }

  block();

  if (restorePrevious) {
    [LTGLContext setCurrentContext:previousContext];
  }
}

- (void)clearColor:(LTVector4)colorValue depth:(GLfloat)depthValue {
  [self clearDepth:depthValue];
  [self clearColor:colorValue];
}

- (void)clearColor:(LTVector4)color {
  LTVector4 previousColor;
  glGetFloatv(GL_COLOR_CLEAR_VALUE, previousColor.data());

  glClearColor(color.r(), color.g(), color.b(), color.a());
  glClear(GL_COLOR_BUFFER_BIT);
  glClearColor(previousColor.r(), previousColor.g(), previousColor.b(), previousColor.a());
}

- (void)clearDepth:(GLfloat)depth {
  GLfloat oldDepthValue;
  glGetFloatv(GL_DEPTH_CLEAR_VALUE, &oldDepthValue);

  glClearDepthf(depth);
  glClear(GL_DEPTH_BUFFER_BIT);
  glClearDepthf(oldDepthValue);
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

- (void)setDepthRange:(LTGLDepthRange)depthRange {
  if (_depthRange.nearPlane == depthRange.nearPlane &&
      _depthRange.farPlane == depthRange.farPlane) {
    return;
  }
  _depthRange = depthRange;
  [self assertContextIsCurrentContext];
  glDepthRangef(_depthRange.nearPlane, _depthRange.farPlane);
}

- (void)setDepthMask:(BOOL)depthMask {
  if (_depthMask == depthMask) {
    return;
  }
  _depthMask = depthMask;
  [self assertContextIsCurrentContext];
  glDepthMask(_depthMask);
}

- (void)setDepthFunc:(LTGLFunction)depthFunc {
  if (_depthFunc == depthFunc) {
    return;
  }
  _depthFunc = depthFunc;
  [self assertContextIsCurrentContext];
  glDepthFunc(_depthFunc);
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
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  auto description = [NSString stringWithFormat:@"%@: %p, resourceCount: %lu",
                      [self class], self, (unsigned long)self.nameToResource.count];

  if (self.nameToResource.count) {
    description = [NSString stringWithFormat:@"%@, resources:\n ", description];
    auto resourcesDescription = [NSMutableArray<NSString *> array];
    for (NSString *name in self.nameToResource) {
      id<LTGPUResource> resource = [self.nameToResource objectForKey:name];
      [resourcesDescription addObject:[NSString stringWithFormat:@"%@: %@", name, resource]];
    }
    description = [NSString stringWithFormat:@"%@%@", description,
                   [resourcesDescription componentsJoinedByString:@",\n "]];
  }

  return [NSString stringWithFormat:@"<%@>", description];
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

- (GLint)maxFragmentTextureUnits {
  if (!_maxFragmentTextureUnits) {
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &_maxFragmentTextureUnits);
  }
  return _maxFragmentTextureUnits;
}

- (GLint)maxNumberOfVertexUniforms {
  if (!_maxNumberOfVertexUniforms) {
    glGetIntegerv(GL_MAX_VERTEX_UNIFORM_VECTORS, &_maxNumberOfVertexUniforms);

  }
  return _maxNumberOfVertexUniforms;
}

- (GLint)maxNumberOfFragmentUniforms {
  if (!_maxNumberOfFragmentUniforms) {
    glGetIntegerv(GL_MAX_FRAGMENT_UNIFORM_VECTORS, &_maxNumberOfFragmentUniforms);

  }
  return _maxNumberOfFragmentUniforms;
}

- (GLint)maxNumberOfColorAttachmentPoints {
  if (!_maxNumberOfColorAttachmentPoints) {
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &_maxNumberOfColorAttachmentPoints);
  }
  return _maxNumberOfColorAttachmentPoints;
}

- (BOOL)canRenderToHalfFloatColorBuffers {
  return [self.supportedExtensions containsObject:@"GL_EXT_color_buffer_half_float"];
}

- (BOOL)canRenderToFloatColorBuffers {
  return [self.supportedExtensions containsObject:@"GL_EXT_color_buffer_float"];
}

- (BOOL)supportsRGTextures {
  return self.version == LTGLVersion3 ||
      [self.supportedExtensions containsObject:@"GL_EXT_texture_rg"];
}

@end

NS_ASSUME_NONNULL_END
