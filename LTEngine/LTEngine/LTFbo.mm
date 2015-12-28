// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTGLContext.h"
#import "LTTexture+Writing.h"

@interface LTFbo ()

/// Texture associated with the FBO.
@property (strong, nonatomic) LTTexture *texture;

/// Mip map level of the the texture associated with the FBO.
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

    if (!texture.name) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's name is 0"];
    }
    if (CGSizeEqualToSize(texture.size, CGSizeZero)) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture's size is (0, 0)"];
    }

    [self verifyTextureAsRenderTarget:texture withContext:context];

    self.previousViewport = CGRectNull;
    self.texture = texture;
    self.level = (GLint)level;

    [self createFramebuffer];
  }
  return self;
}

- (void)dealloc {
  if (self.framebuffer) {
    [self bindAndExecute:^{
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, self.level);
    }];
    glDeleteFramebuffers(1, &_framebuffer);
  }
  LTGLCheckDbg(@"Failed to delete framebuffer: %d", self.framebuffer);
}

- (void)verifyTextureAsRenderTarget:(LTTexture *)texture withContext:(LTGLContext *)context {
  if (texture.dataType == LTGLPixelDataTypeUnorm && texture.bitDepth == LTGLPixelBitDepth8) {
    // Rendering to byte precision is always available by the spec of OpenGL ES 2.0 and 3.0.
    return;
  } else if (texture.dataType == LTGLPixelDataTypeFloat &&
             texture.bitDepth == LTGLPixelBitDepth16) {
    if (!context.canRenderToHalfFloatTextures) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture has a pixel format "
       "type %@, which is unsupported as a render target on this device", texture.pixelFormat];
    }
  } else if (texture.dataType == LTGLPixelDataTypeFloat &&
             texture.bitDepth == LTGLPixelBitDepth32) {
    if (!context.canRenderToFloatTextures) {
      [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture has pixel format "
       "type %@, which is unsupported as a render target on this device", texture.pixelFormat];
    }
  } else {
    [LTGLException raise:kLTFboInvalidTextureException format:@"Given texture has an unsupported "
     "pixel format type %@, which is unsupported as a render target on this device",
     texture.pixelFormat];
  }
}

- (void)createFramebuffer {
  glGenFramebuffers(1, &_framebuffer);
  LTGLCheck(@"Framebuffer creation failed");

  [self bindAndExecute:^{
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           self.texture.name, self.level);
    LTGLCheck(@"Failed attaching texture to framebuffer (texture: %@)", self.texture);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      [LTGLException raise:kLTFboCreationFailedException format:@"Failed creating framebuffer "
       "(status: 0x%x, framebuffer: %d, texture: %@, level: %d)", status, self.framebuffer,
       self.texture, self.level];
    }

    LTGLCheck(@"Error while creating framebuffer");
  }];
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
  CGSize size = self.texture.size / std::pow(2, self.level);
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
    [self.texture writeToAttachmentWithBlock:block];
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
    [self.texture clearAttachmentWithColor:color block:^{
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

- (CGSize)size {
  return self.texture.size;
}

- (LTGLPixelFormat *)pixelFormat {
  return self.texture.pixelFormat;
}

- (LTVector4)fillColor {
  return self.texture.fillColor;
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (id)debugQuickLookObject {
  return [self.texture performSelector:@selector(debugQuickLookObject)];
}

@end
