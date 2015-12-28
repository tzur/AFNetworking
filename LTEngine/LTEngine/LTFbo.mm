// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTFboAttachment.h"
#import "LTFboWritableAttachment.h"
#import "LTGLContext.h"
#import "LTRenderbuffer+Writing.h"
#import "LTTexture+Writing.h"

@interface LTFbo ()

/// Writable attachment attached to this framebuffer.
@property (strong, readwrite, nonatomic) id<LTFboWritableAttachment> writableAttachment;

/// Mip map level of the the texture attached to this framebuffer.
@property (nonatomic) GLint level;

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
#pragma mark Initialization and Setup
#pragma mark -

- (instancetype)initWithTexture:(LTTexture *)texture {
  return [self initWithTexture:texture level:0];
}

- (instancetype)initWithTexture:(LTTexture *)texture level:(NSUInteger)level {
  return [self initWithTexture:texture level:level context:[LTGLContext currentContext]];
}

- (instancetype)initWithTexture:(LTTexture *)texture context:(LTGLContext *)context {
  return [self initWithTexture:texture level:0 context:context];
}

- (instancetype)initWithTexture:(LTTexture *)texture level:(NSUInteger)level
                        context:(LTGLContext *)context {
  if (self = [super init]) {
    LTParameterAssert(texture);
    LTParameterAssert((GLint)level <= texture.maxMipmapLevel);

    if (CGSizeEqualToSize(texture.size, CGSizeZero)) {
      [LTGLException raise:kLTFboInvalidAttachmentException
                    format:@"Given texture's size is (0, 0)"];
    }

    [self verifyTextureAsRenderTarget:texture withContext:context];

    self.previousViewport = CGRectNull;
    self.writableAttachment = texture;
    self.level = (GLint)level;

    [self createFramebuffer];
  }
  return self;
}

- (instancetype)initWithRenderbuffer:(LTRenderbuffer *)renderbuffer {
  if (self = [super init]) {
    LTParameterAssert(renderbuffer);

    if (CGSizeEqualToSize(renderbuffer.size, CGSizeZero)) {
      [LTGLException raise:kLTFboInvalidAttachmentException
                    format:@"Given renderbuffer's size is (0, 0)"];
    }

    self.previousViewport = CGRectNull;
    self.writableAttachment = renderbuffer;

    [self createFramebuffer];
  }
  return self;
}

- (void)verifyTextureAsRenderTarget:(LTTexture *)texture withContext:(LTGLContext *)context {
  if (texture.dataType == LTGLPixelDataTypeUnorm && texture.bitDepth == LTGLPixelBitDepth8) {
    // Rendering to byte precision is always available by the spec of OpenGL ES 2.0 and 3.0.
    return;
  } else if (texture.dataType == LTGLPixelDataTypeFloat &&
             texture.bitDepth == LTGLPixelBitDepth16) {
    if (!context.canRenderToHalfFloatTextures) {
      [LTGLException raise:kLTFboInvalidAttachmentException format:@"Given texture has a pixel "
       "format %@, which is unsupported as a render target on this device", texture.pixelFormat];
    }
  } else if (texture.dataType == LTGLPixelDataTypeFloat &&
             texture.bitDepth == LTGLPixelBitDepth32) {
    if (!context.canRenderToFloatTextures) {
      [LTGLException raise:kLTFboInvalidAttachmentException format:@"Given texture has pixel "
       "format %@, which is unsupported as a render target on this device", texture.pixelFormat];
    }
  } else {
    [LTGLException raise:kLTFboInvalidAttachmentException format:@"Given texture has an "
     "unsupported pixel format %@, which is unsupported as a render target on this device",
     texture.pixelFormat];
  }
}

- (void)createFramebuffer {
  glGenFramebuffers(1, &_framebuffer);
  LTGLCheck(@"Framebuffer creation failed");

  [self bindAndExecute:^{
    [self attachAttachment];

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
       "(status: 0x%x, framebuffer: %d, attachment: %@, level: %d)", status, self.framebuffer,
       self.attachment, self.level];
    }

    LTGLCheck(@"Error while creating framebuffer");
  }];
}

- (void)attachAttachment {
  switch (self.attachment.attachmentType) {
    case LTFboAttachmentTypeTexture2D:
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                             self.attachment.name, self.level);
      LTGLCheck(@"Failed attaching texture to framebuffer (texture: %@)", self.attachment);
      break;
    case LTFboAttachmentTypeRenderbuffer:
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,
                                self.attachment.name);
      LTGLCheck(@"Failed attaching renderbuffer to framebuffer (renderbuffer: %@)",
                self.attachment);
      break;
  }
}

- (void)dealloc {
  if (self.framebuffer) {
    [self bindAndExecute:^{
      [self detachAttachment];
    }];

    glDeleteFramebuffers(1, &_framebuffer);
    LTGLCheckDbg(@"Failed to delete framebuffer: %d", self.framebuffer);
  }
}

- (void)detachAttachment {
  switch (self.attachmentType) {
    case LTFboAttachmentTypeRenderbuffer:
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, 0);
      break;
    case LTFboAttachmentTypeTexture2D:
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, self.level);
      break;
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
    [self.writableAttachment writeToAttachmentWithBlock:block];
  }];
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
  [self bindAndExecute:^{
    [self.writableAttachment clearAttachmentWithColor:color block:^{
      [[LTGLContext currentContext] clearWithColor:color];
    }];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (GLuint)name {
  return self.framebuffer;
}

- (id<LTFboAttachment>)attachment {
  return self.writableAttachment;
}

- (CGSize)size {
  return self.writableAttachment.size;
}

- (LTFboAttachmentType)attachmentType {
  return self.writableAttachment.attachmentType;
}

- (LTGLPixelFormat *)pixelFormat {
  return self.writableAttachment.pixelFormat;
}

- (LTVector4)fillColor {
  return self.writableAttachment.fillColor;
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
