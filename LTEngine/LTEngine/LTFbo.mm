// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTFboAttachable.h"
#import "LTFboAttachmentInfo.h"
#import "LTGLContext.h"
#import "LTRenderbuffer.h"
#import "LTTexture+Writing.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTFbo ()

/// Dictionary mapping LTFboAttachmentPoint to \c LTFboAttachmentInfo.
@property (readonly, nonatomic) NSDictionary<NSNumber *, LTFboAttachmentInfo *> *attachmentInfos;

/// Framebuffer identifier.
@property (nonatomic) GLuint framebuffer;

/// Set to the previously bound framebuffer, or \c 0 if the framebuffer is not bound.
@property (nonatomic) GLint previousFramebuffer;

/// Viewport to restore when the current framebuffer unbinds.
@property (nonatomic) CGRect previousViewport;

/// YES if the program is currently bound.
@property (nonatomic) BOOL bound;

@end

@implementation LTFbo

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithAttachmentInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos {
  return [self initWithContext:[LTGLContext currentContext] attachmentInfos:infos];
}

- (instancetype)initWithAttachables:(NSDictionary<NSNumber *, id<LTFboAttachable>> *)attachables {
  auto infos = [NSMutableDictionary<NSNumber *, LTFboAttachmentInfo *> dictionary];
  for (NSNumber *attachmentPoint in attachables) {
    infos[attachmentPoint] = [LTFboAttachmentInfo withAttachable:attachables[attachmentPoint]];
  }
  return [self initWithAttachmentInfos:[infos copy]];
}

- (instancetype)initWithTexture:(LTTexture *)texture {
  return [self initWithTexture:texture level:0];
}

- (instancetype)initWithTexture:(LTTexture *)texture level:(GLint)level {
  return [self initWithTexture:texture level:level context:[LTGLContext currentContext]];
}

- (instancetype)initWithRenderbuffer:(LTRenderbuffer *)renderbuffer {
  return [self initWithAttachmentInfos:@{
    @(LTFboAttachmentPointColor0):[LTFboAttachmentInfo withAttachable:renderbuffer]
  }];
}

- (instancetype)initWithTexture:(LTTexture *)texture context:(LTGLContext *)context {
  return [self initWithTexture:texture level:0 context:context];
}

- (instancetype)initWithTexture:(LTTexture *)texture level:(GLint)level
                        context:(LTGLContext *)context {
  return [self initWithContext:context attachmentInfos:@{
    @(LTFboAttachmentPointColor0): [LTFboAttachmentInfo withAttachable:texture level:level]
  }];
}

- (instancetype)initWithContext:(LTGLContext *)context
                attachmentInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos {
  if (self = [super init]) {
    LTParameterAssert(infos.count, @"No attachables given");
    _attachmentInfos = infos;
    self.previousViewport = CGRectNull;
    [self verifyAttachablesWithContext:context];
    [self createFramebuffer];
  }
  return self;
}

- (void)verifyAttachablesWithContext:(LTGLContext *)context {
  LTParameterAssert((GLint)[self colorAttachablesCount] <= context.maxNumberOfColorAttachmentPoints,
                    @"%lu exceeds max number of color attachables %d",
                    (unsigned long)[self colorAttachablesCount],
                    context.maxNumberOfColorAttachmentPoints);

  [self enumerateAttachablesWithBlock:^(NSNumber *attachmentPoint, LTFboAttachmentInfo *info,
                                        BOOL *) {
    [self verifySizeOfAttachableInfo:info atPoint:attachmentPoint];
    [self verifyAsRenderTargetAttachableInfo:info atPoint:attachmentPoint withContext:context];
    [self verifyLevelOfAttachableInfo:info];
  }];
}

- (void)verifySizeOfAttachableInfo:(LTFboAttachmentInfo *)info atPoint:(NSNumber *)attachmentPoint {
  if (info.attachable.size == CGSizeZero) {
    [LTGLException raise:kLTFboInvalidAttachmentException format:@"Size of an attachable (%@)"
     " at attachmentPoint %ld is (0, 0)", info, (long)attachmentPoint.integerValue];
  }
}

- (void)verifyLevelOfAttachableInfo:(LTFboAttachmentInfo *)info {
  if (info.attachable.attachableType != LTFboAttachableTypeTexture2D) {
    return;
  };

  auto texture = (LTTexture *)info.attachable;
  if (info.level > texture.maxMipmapLevel) {
    [LTGLException raise:NSInvalidArgumentException format:@"Texture (%@) attachable level %ld "
     "must be less than or equal to %d", texture, (unsigned long)info.level,
     texture.maxMipmapLevel];
  };
}

- (NSUInteger)colorAttachablesCount {
  __block NSUInteger count = 0;
  [self enumerateColorAttachablesWithBlock:^(NSNumber *, LTFboAttachmentInfo *, BOOL *) {
    count++;
  }];
  return count;
}

- (void)verifyAsRenderTargetAttachableInfo:(LTFboAttachmentInfo *)info
                                   atPoint:(NSNumber *)attachmentPoint
                               withContext:(LTGLContext *)context {
  if (attachmentPoint.unsignedIntegerValue == LTFboAttachmentPointDepth) {
    return;
  }

  auto attachable = info.attachable;
  if (attachable.pixelFormat.dataType == LTGLPixelDataType8Unorm) {
    // Rendering to byte precision is always available by the spec of OpenGL ES 2.0 and 3.0.
    return;
  } else if (attachable.pixelFormat.dataType == LTGLPixelDataType16Float) {
    if (!context.canRenderToHalfFloatTextures) {
      [LTGLException raise:kLTFboInvalidAttachmentException format:@"Given attachable has a pixel "
       "format %@, which is unsupported as a render target on this device", attachable.pixelFormat];
    }
  } else if (attachable.pixelFormat.dataType == LTGLPixelDataType32Float) {
    if (!context.canRenderToFloatTextures) {
      [LTGLException raise:kLTFboInvalidAttachmentException format:@"Given attachable has pixel "
       "format %@, which is unsupported as a render target on this device", attachable.pixelFormat];
    }
  } else {
    [LTGLException raise:kLTFboInvalidAttachmentException format:@"Given attachable has an "
     "unsupported pixel format %@, which is unsupported as a render target on this device",
     attachable.pixelFormat];
  }
}

- (void)createFramebuffer {
  glGenFramebuffers(1, &_framebuffer);
  LTGLCheck(@"Framebuffer creation failed");

  [self bindAndExecute:^{
    for (NSNumber *attachmentPoint in self.attachmentInfos) {
      [self attachUsingAttachableInfo:self.attachmentInfos[attachmentPoint]
                              atPoint:(LTFboAttachmentPoint)attachmentPoint.integerValue];
    }

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
       "(status: 0x%x, framebuffer: %d, attachmentInfos %@)", status, self.framebuffer,
       self.attachmentInfos];
    }

    LTGLCheck(@"Error while creating framebuffer");
  }];
}

- (void)attachUsingAttachableInfo:(LTFboAttachmentInfo *)info
                          atPoint:(LTFboAttachmentPoint)attachmentPoint {
  switch (info.attachable.attachableType) {
    case LTFboAttachableTypeTexture2D:
      glFramebufferTexture2D(GL_FRAMEBUFFER, attachmentPoint, GL_TEXTURE_2D, info.attachable.name,
                             info.level);
      LTGLCheck(@"Failed attaching attachable (%@) to framebuffer (%@)", info.attachable, self);
      break;
    case LTFboAttachableTypeRenderbuffer:
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachmentPoint, GL_RENDERBUFFER,
                                info.attachable.name);
      LTGLCheck(@"Failed attaching renderbuffer (%@) to framebuffer (%@)", info.attachable, self);
      break;
  }
}

- (void)dealloc {
  if (self.framebuffer) {
    // The attachables held by this object, if not held by any other object, are required to be
    // deallocated immediately after this object deallocates. However, the detaching code may add
    // them to the autorelease pool, hence deferring their deallocation to a later time. Wrapping
    // the detaching code in an \c @autoreleasepool guarantees that they will be released if an
    // \c -autorelease message is sent to them. For more details, see https://goo.gl/p3wtCL.
    @autoreleasepool {
      [self bindAndExecute:^{
        [self detachAttachables];
      }];
    }

    glDeleteFramebuffers(1, &_framebuffer);
    LTGLCheckDbg(@"Failed to delete framebuffer: %d", self.framebuffer);
  }
}

- (void)detachAttachables {
  for (NSNumber *attachmentInfo in self.attachmentInfos) {
    auto info = (LTFboAttachmentInfo *)self.attachmentInfos[attachmentInfo];
    auto attachmentPoint = (LTFboAttachmentPoint)attachmentInfo.integerValue;

    switch (info.attachable.attachableType) {
      case LTFboAttachableTypeRenderbuffer:
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachmentPoint, GL_RENDERBUFFER, 0);
        break;
      case LTFboAttachableTypeTexture2D:
        glFramebufferTexture2D(GL_FRAMEBUFFER, attachmentPoint, GL_TEXTURE_2D, 0, info.level);
        break;
    }
  }
}

#pragma mark -
#pragma mark Binding
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }

  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_previousFramebuffer);
  GLint viewport[4];
  glGetIntegerv(GL_VIEWPORT, viewport);
  self.previousViewport = CGRectMake(viewport[0], viewport[1], viewport[2], viewport[3]);

  glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
  CGSize size = self.attachment.size / std::pow(2, self.level);
  glViewport(0, 0, size.width, size.height);
  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  glBindFramebuffer(GL_FRAMEBUFFER, self.previousFramebuffer);
  if (!CGRectIsNull(self.previousViewport)) {
    glViewport(self.previousViewport.origin.x, self.previousViewport.origin.y,
               self.previousViewport.size.width, self.previousViewport.size.height);
  }

  self.previousFramebuffer = 0;
  self.previousViewport = CGRectNull;
  self.bound = NO;
}

- (void)setContextWithRenderingToScreen:(BOOL)renderingToScreen andDraw:(LTVoidBlock)block {
  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.renderingToScreen = renderingToScreen;
    // New framebuffer is attached, there's no point of keeping the previous scissor tests.
    context.scissorTestEnabled = NO;
    block();
  }];
}

- (void)bindAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    [self setContextWithRenderingToScreen:NO andDraw:block];
    [self unbind];
  }
}

- (void)bindAndDraw:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self bindAndExecute:^{
    [self writeToAttachablesStartingAtIndex:0 withBlock:block];
  }];
}

- (void)writeToAttachablesStartingAtIndex:(NSUInteger)index withBlock:(LTVoidBlock)block {
  if (index == [[self class] attachmentPoints].count) {
    block();
    return;
  }

  auto attachmentPoint = [[self class] attachmentPoints][index];
  auto attachmentInfo = self.attachmentInfos[attachmentPoint];

  if (attachmentInfo) {
    [attachmentInfo.attachable writeToAttachableWithBlock:^{
      [self writeToAttachablesStartingAtIndex:index+1 withBlock:block];
    }];
  } else {
    [self writeToAttachablesStartingAtIndex:index+1 withBlock:block];
  }
}

- (void)bindAndDrawOnScreen:(LTVoidBlock)block {
  [self bindAndDraw:^{
    [self setContextWithRenderingToScreen:YES andDraw:block];
  }];
}

#pragma mark -
#pragma mark Operations
#pragma mark -

- (void)clearWithColor:(LTVector4)color {
  // Below each attachable is being cleared (to update its generation id). Later this instance is
  // being cleared using clearWithColor:, which clears with color all color attachables attached to
  // this instance.
  [self enumerateColorAttachablesWithBlock:^(NSNumber *, LTFboAttachmentInfo *info, BOOL *) {
    [self bindAndExecute:^{
      [info.attachable clearAttachableWithColor:color block:^{}];
    }];
  }];

  [self bindAndExecute:^{
    [[LTGLContext currentContext] clearWithColor:color];
  }];
}

- (void)clearDepth:(GLfloat)value {
  if (!self.attachmentInfos[@(LTFboAttachmentPointDepth)]) {
    return;
  }

  [self bindAndExecute:^{
    auto attachable = self.attachmentInfos[@(LTFboAttachmentPointDepth)].attachable;
    [attachable clearAttachableWithColor:LTVector4(value) block:^{
      [[LTGLContext currentContext] clearDepth:value];
    }];
  }];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  auto descriptions = [NSMutableArray<NSString *> array];
  [descriptions addObject:[NSString stringWithFormat:@"%@: %p, framebuffer: %d, bound: %d",
                           [self class], self, self.framebuffer, self.bound]];

  for (NSNumber *attachmentPoint in self.attachmentInfos) {
    [descriptions addObject:[NSString stringWithFormat:@"attachment: %@",
                             self.attachmentInfos[attachmentPoint]]];
  }

  return [NSString stringWithFormat:@"<%@>", [descriptions componentsJoinedByString:@", "]];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (GLuint)name {
  return self.framebuffer;
}

- (CGSize)size {
  return self.attachment.size;
}

- (id<LTFboAttachable>)attachment {
  __block id<LTFboAttachable> attachable;

  [self enumerateAttachablesWithBlock:^(NSNumber *, LTFboAttachmentInfo *info, BOOL *stop) {
    attachable = info.attachable;
    *stop = YES;
  }];

  return attachable;
}

- (LTGLPixelFormat *)pixelFormat {
  return self.attachment.pixelFormat;
}

- (GLint)level {
  __block GLint level;

  [self enumerateAttachablesWithBlock:^(NSNumber *, LTFboAttachmentInfo *info, BOOL *stop) {
    level = info.level;
    *stop = YES;
  }];

  return level;
}

/// Enumeration block of \c LTFbo's attachables. The given \c attachmentPoint and \c info
/// corresponds to \c LTFbo's attachable. Enumeration stops when \c stop is set to YES.
typedef void (^LTFboAttachableEnumerationBlock)(NSNumber *attachmentPoint,
    LTFboAttachmentInfo *info, BOOL *stop);

/// Enumerates all attachables in the priority order, skipping non existing attachables, and calls
/// the given \c block.
- (void)enumerateAttachablesWithBlock:(LTFboAttachableEnumerationBlock)block {
  [self enumerateAttachablesUsingIndices:[[self class] attachmentPoints] block:block];
}

/// Enumerates all color attachables in the priority order, skipping non existing attachables,
/// and calls the given \c block.
- (void)enumerateColorAttachablesWithBlock:(LTFboAttachableEnumerationBlock)block {
  [self enumerateAttachablesUsingIndices:[[self class] colorAttachmentPoints] block:block];
}

- (void)enumerateAttachablesUsingIndices:(NSArray<NSNumber *> *)indices
                                   block:(LTFboAttachableEnumerationBlock)block {
  BOOL stop = NO;
  for (NSNumber *index in indices) {
    if (!self.attachmentInfos[index]) {
      continue;
    }
    block(index, self.attachmentInfos[index], &stop);
    if (stop) {
      break;
    }
  }
}

+ (NSArray<NSNumber *> *)colorAttachmentPoints {
  static NSArray<NSNumber *> *colorAttachmentPoints;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    colorAttachmentPoints = @[
      @(LTFboAttachmentPointColor0),
      @(LTFboAttachmentPointColor1),
      @(LTFboAttachmentPointColor2),
      @(LTFboAttachmentPointColor3)
    ];
  });

  return colorAttachmentPoints;
}

+ (NSArray<NSNumber *> *)attachmentPoints {
  static NSArray<NSNumber *> *attachmentPoints;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    auto colorAttachments = [[self class] colorAttachmentPoints];
    attachmentPoints = [colorAttachments
                        arrayByAddingObjectsFromArray:@[@(LTFboAttachmentPointDepth)]];
  });

  return attachmentPoints;
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (id)debugQuickLookObject {
  if ([self.attachment respondsToSelector:@selector(debugQuickLookObject)]) {
    return [self.attachment performSelector:@selector(debugQuickLookObject)];
  } else {
    return nil;
  }
}

@end

NS_ASSUME_NONNULL_END
